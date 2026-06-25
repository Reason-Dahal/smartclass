require('dotenv').config();
const request = require('supertest');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const app = require('../app');
const User = require('../models/User');
const Teacher = require('../models/Teacher');
const Student = require('../models/Student');
const Program = require('../models/Program');
const Batch = require('../models/Batch');
const Enrollment = require('../models/Enrollment');

let mongoServer;

// ─── SETUP ───────────────────────────────────────────────────────

beforeAll(async () => {
  mongoServer = await MongoMemoryServer.create();
  await mongoose.connect(mongoServer.getUri());
});

afterEach(async () => {
  const collections = mongoose.connection.collections;
  for (const key in collections) {
    await collections[key].deleteMany({});
  }
});

afterAll(async () => {
  await mongoose.disconnect();
  await mongoServer.stop();
});

// ─── HELPERS ─────────────────────────────────────────────────────

const createAdminAndLogin = async () => {
  await User.create({
    name: 'Test Admin',
    email: 'admin@test.com',
    password: 'Admin@123',
    role: 'admin',
    status: 'active',
    mustChangePassword: false,
  });
  const res = await request(app)
    .post('/api/v1/auth/login')
    .send({ email: 'admin@test.com', password: 'Admin@123' });
  return res.body.data.token;
};

const createTeacherAndLogin = async (adminToken) => {
    // Create teacher via admin API
    const res = await request(app)
      .post('/api/v1/admin/teachers')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ name: 'Test Teacher', email: 'teacher@test.com', department: 'CS' });
  
    // Get teacher profile _id
    const teacher = await Teacher.findOne().populate('userId');
  
    // Directly set a known password using save() so pre-save hook hashes it
    const user = await User.findOne({ email: 'teacher@test.com' }).select('+password');
    user.password = 'Teacher@123';
    user.mustChangePassword = false;
    await user.save();
  
    // Now login with the known password
    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: 'teacher@test.com', password: 'Teacher@123' });
  
    return {
      token: loginRes.body.data.token,
      profileId: teacher._id.toString(),
    };
  };

const setupAcademicStructure = async (adminToken) => {
  // Create program
  const programRes = await request(app)
    .post('/api/v1/admin/programs')
    .set('Authorization', `Bearer ${adminToken}`)
    .send({ name: 'BCA', type: 'semester' });
  const program = programRes.body.data.program;

  // Create batch
  const batchRes = await request(app)
    .post(`/api/v1/admin/programs/${program._id}/batches`)
    .set('Authorization', `Bearer ${adminToken}`)
    .send({ name: 'BCA 2023', intakeYear: 2023 });
  const batch = batchRes.body.data.batch;

  return { program, batch };
};

// ─── PROGRAM TESTS ───────────────────────────────────────────────

describe('Batch Management', () => {

  test('should create batch under a program', async () => {
    const token = await createAdminAndLogin();
    const programRes = await request(app)
      .post('/api/v1/admin/programs')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'BCA', type: 'semester' });

    const response = await request(app)
      .post(`/api/v1/admin/programs/${programRes.body.data.program._id}/batches`)
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'BCA 2023', intakeYear: 2023 });

    expect(response.status).toBe(201);
    expect(response.body.data.batch.name).toBe('BCA 2023');
    expect(response.body.data.batch.currentTerm).toBe(1);
  });

  test('should get all batches', async () => {
    const token = await createAdminAndLogin();
    const { program } = await setupAcademicStructure(token);

    await request(app)
      .post(`/api/v1/admin/programs/${program._id}/batches`)
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'BCA 2024', intakeYear: 2024 });

    const response = await request(app)
      .get('/api/v1/admin/programs/batches')
      .set('Authorization', `Bearer ${token}`);

    expect(response.status).toBe(200);
    expect(response.body.data.batches.length).toBeGreaterThanOrEqual(2);
  });

  test('should promote batch to next term', async () => {
    const token = await createAdminAndLogin();
    const { batch } = await setupAcademicStructure(token);

    const response = await request(app)
      .post(`/api/v1/admin/programs/batches/${batch._id}/promote`)
      .set('Authorization', `Bearer ${token}`);

    expect(response.status).toBe(200);
    expect(response.body.data.message).toContain('Term 1 to Term 2');

    const updatedBatch = await Batch.findById(batch._id);
    expect(updatedBatch.currentTerm).toBe(2);
  });

  test('should not promote batch beyond totalTerms', async () => {
    const token = await createAdminAndLogin();

    const programRes = await request(app)
      .post('/api/v1/admin/programs')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'BCA', type: 'semester' });

    const batchRes = await request(app)
      .post(`/api/v1/admin/programs/${programRes.body.data.program._id}/batches`)
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'BCA 2015', intakeYear: 2015 });

    const batchId = batchRes.body.data.batch._id;

    // Manually set to final term
    await Batch.findByIdAndUpdate(batchId, { currentTerm: 8 });

    const response = await request(app)
      .post(`/api/v1/admin/programs/batches/${batchId}/promote`)
      .set('Authorization', `Bearer ${token}`);

    expect(response.status).toBe(400);
    expect(response.body.error.code).toBe('PROMOTION_LIMIT');
  });
});

// ─── COURSE TESTS ────────────────────────────────────────────────

describe('Course Management', () => {

  test('should create a course', async () => {
    const adminToken = await createAdminAndLogin();
    const { program } = await setupAcademicStructure(adminToken);
    const { profileId } = await createTeacherAndLogin(adminToken);

    const response = await request(app)
      .post('/api/v1/courses')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        programId: program._id,
        teacherId: profileId,
        subjectName: 'Data Structures',
        term: 1,
        isElective: false,
      });

    expect(response.status).toBe(201);
    expect(response.body.data.course.subjectName).toBe('Data Structures');
    expect(response.body.data.course.isElective).toBe(false);
  });

  test('should return 400 for term out of range', async () => {
    const adminToken = await createAdminAndLogin();
    const { program } = await setupAcademicStructure(adminToken);
    const { profileId } = await createTeacherAndLogin(adminToken);

    const response = await request(app)
      .post('/api/v1/courses')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        programId: program._id,
        teacherId: profileId,
        subjectName: 'Data Structures',
        term: 9, // BCA only has 8 terms
        isElective: false,
      });

    expect(response.status).toBe(400);
  });

  test('should return 400 for duplicate course', async () => {
    const adminToken = await createAdminAndLogin();
    const { program } = await setupAcademicStructure(adminToken);
    const { profileId } = await createTeacherAndLogin(adminToken);

    await request(app)
      .post('/api/v1/courses')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        programId: program._id,
        teacherId: profileId,
        subjectName: 'Data Structures',
        term: 1,
        isElective: false,
      });

    const response = await request(app)
      .post('/api/v1/courses')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        programId: program._id,
        teacherId: profileId,
        subjectName: 'Data Structures',
        term: 1,
        isElective: false,
      });

    expect(response.status).toBe(400);
    expect(response.body.error.code).toBe('DUPLICATE');
  });

  test('teacher should see their assigned courses', async () => {
    const adminToken = await createAdminAndLogin();
    const { program } = await setupAcademicStructure(adminToken);
    const { profileId, token: teacherToken } =
        await createTeacherAndLogin(adminToken);

    await request(app)
      .post('/api/v1/courses')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        programId: program._id,
        teacherId: profileId,
        subjectName: 'Data Structures',
        term: 1,
        isElective: false,
      });

      const response = await request(app)
      .get('/api/v1/courses/teacher/my-courses')
      .set('Authorization', `Bearer ${teacherToken}`);

    expect(response.status).toBe(200);
    expect(response.body.data.courses).toHaveLength(1);
    expect(response.body.data.courses[0].subjectName)
        .toBe('Data Structures');
  });
});

// ─── ENROLLMENT TESTS ────────────────────────────────────────────

describe('Student Enrollment', () => {

  test('batch promotion should auto-enroll students in compulsory courses', async () => {
    const adminToken = await createAdminAndLogin();
    const { program, batch } = await setupAcademicStructure(adminToken);
    const { profileId } = await createTeacherAndLogin(adminToken);

    // Create student
    const studentRes = await request(app)
      .post('/api/v1/admin/students')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        name: 'Aarav Sharma',
        email: 'aarav@test.com',
        rollNumber: 'BCA-2023-001',
        programId: program._id,
        batchId: batch._id,
      });

    // Create compulsory course for term 2
    await request(app)
      .post('/api/v1/courses')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        programId: program._id,
        teacherId: profileId,
        subjectName: 'Data Structures',
        term: 2,
        isElective: false,
      });

    // Promote batch from term 1 to term 2
    await request(app)
      .post(`/api/v1/admin/programs/batches/${batch._id}/promote`)
      .set('Authorization', `Bearer ${adminToken}`);

    // Check enrollment was created
    const student = await Student.findOne({ userId: studentRes.body.data.student.id });
    const enrollments = await Enrollment.find({ studentId: student._id });

    expect(enrollments).toHaveLength(1);
    expect(enrollments[0].enrollmentType).toBe('compulsory');
  });
});