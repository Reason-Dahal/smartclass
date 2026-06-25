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

let mongoServer;
let adminToken;

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
  adminToken = null;
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

const createProgram = async (token) => {
  const res = await request(app)
    .post('/api/v1/admin/programs')
    .set('Authorization', `Bearer ${token}`)
    .send({ name: 'BCA', type: 'semester' });
  return res.body.data.program;
};

const createBatch = async (token, programId) => {
  const res = await request(app)
    .post(`/api/v1/admin/programs/${programId}/batches`)
    .set('Authorization', `Bearer ${token}`)
    .send({ name: 'BCA 2023', intakeYear: 2023 });
  return res.body.data.batch;
};

// ─── TEACHER TESTS ───────────────────────────────────────────────

describe('POST /api/v1/admin/teachers', () => {

  test('should create teacher successfully', async () => {
    const token = await createAdminAndLogin();

    const response = await request(app)
      .post('/api/v1/admin/teachers')
      .set('Authorization', `Bearer ${token}`)
      .send({
        name: 'Rajan Thapa',
        email: 'rajan@test.com',
        department: 'Computer Science',
      });

    expect(response.status).toBe(201);
    expect(response.body.success).toBe(true);
    expect(response.body.data.teacher.name).toBe('Rajan Thapa');
    expect(response.body.data.teacher.email).toBe('rajan@test.com');
  });

  test('should return 400 for duplicate email', async () => {
    const token = await createAdminAndLogin();

    await request(app)
      .post('/api/v1/admin/teachers')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Rajan Thapa', email: 'rajan@test.com', department: 'CS' });

    const response = await request(app)
      .post('/api/v1/admin/teachers')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Another Teacher', email: 'rajan@test.com', department: 'Math' });

    expect(response.status).toBe(400);
    expect(response.body.error.code).toBe('DUPLICATE_EMAIL');
  });

  test('should return 400 when required fields are missing', async () => {
    const token = await createAdminAndLogin();

    const response = await request(app)
      .post('/api/v1/admin/teachers')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Rajan Thapa' }); // missing email and department

    expect(response.status).toBe(400);
    expect(response.body.error.code).toBe('VALIDATION_ERROR');
  });

  test('should return 401 without token', async () => {
    const response = await request(app)
      .post('/api/v1/admin/teachers')
      .send({ name: 'Rajan Thapa', email: 'rajan@test.com', department: 'CS' });

    expect(response.status).toBe(401);
  });

  test('should return 403 when non-admin tries to create teacher', async () => {
    // Create a teacher user and login as teacher
    await User.create({
      name: 'Teacher User',
      email: 'teacher@test.com',
      password: 'Teacher@123',
      role: 'teacher',
      status: 'active',
      mustChangePassword: false,
    });

    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: 'teacher@test.com', password: 'Teacher@123' });

    const teacherToken = loginRes.body.data.token;

    const response = await request(app)
      .post('/api/v1/admin/teachers')
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({ name: 'New Teacher', email: 'new@test.com', department: 'CS' });

    expect(response.status).toBe(403);
  });

  test('should create Teacher profile document in database', async () => {
    const token = await createAdminAndLogin();

    await request(app)
      .post('/api/v1/admin/teachers')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Rajan Thapa', email: 'rajan@test.com', department: 'Computer Science' });

    const teacher = await Teacher.findOne().populate('userId');
    expect(teacher).not.toBeNull();
    expect(teacher.department).toBe('Computer Science');
    expect(teacher.userId.email).toBe('rajan@test.com');
  });

  test('new teacher should have mustChangePassword set to true', async () => {
    const token = await createAdminAndLogin();

    await request(app)
      .post('/api/v1/admin/teachers')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Rajan Thapa', email: 'rajan@test.com', department: 'CS' });

    const user = await User.findOne({ email: 'rajan@test.com' });
    expect(user.mustChangePassword).toBe(true);
  });
});

describe('GET /api/v1/admin/teachers', () => {

  test('should return list of teachers', async () => {
    const token = await createAdminAndLogin();

    await request(app)
      .post('/api/v1/admin/teachers')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Teacher One', email: 'one@test.com', department: 'CS' });

    await request(app)
      .post('/api/v1/admin/teachers')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Teacher Two', email: 'two@test.com', department: 'Math' });

    const response = await request(app)
      .get('/api/v1/admin/teachers')
      .set('Authorization', `Bearer ${token}`);

    expect(response.status).toBe(200);
    expect(response.body.data.teachers).toHaveLength(2);
  });

  test('should return empty array when no teachers exist', async () => {
    const token = await createAdminAndLogin();

    const response = await request(app)
      .get('/api/v1/admin/teachers')
      .set('Authorization', `Bearer ${token}`);

    expect(response.status).toBe(200);
    expect(response.body.data.teachers).toHaveLength(0);
  });
});

// ─── STUDENT TESTS ───────────────────────────────────────────────

describe('POST /api/v1/admin/students', () => {

  test('should create student successfully', async () => {
    const token = await createAdminAndLogin();
    const program = await createProgram(token);
    const batch = await createBatch(token, program._id);

    const response = await request(app)
      .post('/api/v1/admin/students')
      .set('Authorization', `Bearer ${token}`)
      .send({
        name: 'Aarav Sharma',
        email: 'aarav@test.com',
        rollNumber: 'BCA-2023-001',
        programId: program._id,
        batchId: batch._id,
      });

    expect(response.status).toBe(201);
    expect(response.body.success).toBe(true);
    expect(response.body.data.student.name).toBe('Aarav Sharma');
  });

  test('should return 404 when program does not exist', async () => {
    const token = await createAdminAndLogin();
    const fakeId = new mongoose.Types.ObjectId();

    const response = await request(app)
      .post('/api/v1/admin/students')
      .set('Authorization', `Bearer ${token}`)
      .send({
        name: 'Aarav Sharma',
        email: 'aarav@test.com',
        rollNumber: 'BCA-2023-001',
        programId: fakeId,
        batchId: fakeId,
      });

    expect(response.status).toBe(404);
  });

  test('should return 400 for duplicate email', async () => {
    const token = await createAdminAndLogin();
    const program = await createProgram(token);
    const batch = await createBatch(token, program._id);

    await request(app)
      .post('/api/v1/admin/students')
      .set('Authorization', `Bearer ${token}`)
      .send({
        name: 'Aarav Sharma',
        email: 'aarav@test.com',
        rollNumber: 'BCA-2023-001',
        programId: program._id,
        batchId: batch._id,
      });

    const response = await request(app)
      .post('/api/v1/admin/students')
      .set('Authorization', `Bearer ${token}`)
      .send({
        name: 'Aarav Sharma 2',
        email: 'aarav@test.com',
        rollNumber: 'BCA-2023-002',
        programId: program._id,
        batchId: batch._id,
      });

    expect(response.status).toBe(400);
    expect(response.body.error.code).toBe('DUPLICATE_EMAIL');
  });
});

// ─── PROGRAM TESTS ───────────────────────────────────────────────

describe('POST /api/v1/admin/programs', () => {

  test('should create semester program with 8 terms', async () => {
    const token = await createAdminAndLogin();

    const response = await request(app)
      .post('/api/v1/admin/programs')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'BCA', type: 'semester' });

    expect(response.status).toBe(201);
    expect(response.body.data.program.totalTerms).toBe(8);
    expect(response.body.data.program.name).toBe('BCA');
  });

  test('should create year program with 4 terms', async () => {
    const token = await createAdminAndLogin();

    const response = await request(app)
      .post('/api/v1/admin/programs')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'BBS', type: 'year' });

    expect(response.status).toBe(201);
    expect(response.body.data.program.totalTerms).toBe(4);
  });

  test('should return 400 for duplicate program name', async () => {
    const token = await createAdminAndLogin();

    await request(app)
      .post('/api/v1/admin/programs')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'BCA', type: 'semester' });

    const response = await request(app)
      .post('/api/v1/admin/programs')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'BCA', type: 'year' });

    expect(response.status).toBe(400);
    expect(response.body.error.code).toBe('DUPLICATE_NAME');
  });

  test('should return 400 for invalid program type', async () => {
    const token = await createAdminAndLogin();

    const response = await request(app)
      .post('/api/v1/admin/programs')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'BCA', type: 'invalid' });

    expect(response.status).toBe(400);
  });
});

// ─── USER STATUS TESTS ───────────────────────────────────────────

describe('PATCH /api/v1/admin/users/:id/status', () => {

  test('should suspend a teacher account', async () => {
    const token = await createAdminAndLogin();

    const createRes = await request(app)
      .post('/api/v1/admin/teachers')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Rajan Thapa', email: 'rajan@test.com', department: 'CS' });

    const teacherUserId = createRes.body.data.teacher.id;

    const response = await request(app)
      .patch(`/api/v1/admin/users/${teacherUserId}/status`)
      .set('Authorization', `Bearer ${token}`)
      .send({ status: 'suspended' });

    expect(response.status).toBe(200);

    const user = await User.findById(teacherUserId);
    expect(user.status).toBe('suspended');
  });

  test('should return 400 for invalid status value', async () => {
    const token = await createAdminAndLogin();
    const fakeId = new mongoose.Types.ObjectId();

    const response = await request(app)
      .patch(`/api/v1/admin/users/${fakeId}/status`)
      .set('Authorization', `Bearer ${token}`)
      .send({ status: 'banned' }); // invalid status

    expect(response.status).toBe(400);
  });

  test('should not allow changing admin status', async () => {
    const token = await createAdminAndLogin();
    const adminUser = await User.findOne({ role: 'admin' });

    const response = await request(app)
      .patch(`/api/v1/admin/users/${adminUser._id}/status`)
      .set('Authorization', `Bearer ${token}`)
      .send({ status: 'suspended' });

    expect(response.status).toBe(403);
  });
});