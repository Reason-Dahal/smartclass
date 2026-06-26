require('dotenv').config();
const request = require('supertest');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const app = require('../app');
const User = require('../models/User');
const Batch = require('../models/Batch');

let mongoServer;

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

// ─── PASSWORD VALIDATION EDGE CASES ──────────────────────────────
// These test the User model validator — not just "does it work"
// but "does it correctly REJECT bad input"

describe('Password validation edge cases', () => {

    test('should reject password without uppercase letter', async () => {
      // Test directly against User model validator
      const User = require('../models/User');
      let error;
      try {
        await User.create({
          name: 'Test User',
          email: 'test@test.com',
          password: 'allowercase1!', // no uppercase
          role: 'teacher',
          status: 'active',
        });
      } catch (e) {
        error = e;
      }
      expect(error).toBeDefined();
      expect(error.message).toContain('uppercase');
    });
  
    test('should reject password without special character', async () => {
      const User = require('../models/User');
      let error;
      try {
        await User.create({
          name: 'Test User',
          email: 'test@test.com',
          password: 'NoSpecial123', // no special character
          role: 'teacher',
          status: 'active',
        });
      } catch (e) {
        error = e;
      }
      expect(error).toBeDefined();
      expect(error.message).toContain('special');
    });
  
    test('should reject password shorter than 8 characters', async () => {
      const User = require('../models/User');
      let error;
      try {
        await User.create({
          name: 'Test User',
          email: 'test@test.com',
          password: 'Ab1!', // too short
          role: 'teacher',
          status: 'active',
        });
      } catch (e) {
        error = e;
      }
      expect(error).toBeDefined();
    });
  
    test('should accept valid password', async () => {
      const User = require('../models/User');
      const user = await User.create({
        name: 'Test User',
        email: 'test@test.com',
        password: 'Valid@123', // meets all requirements
        role: 'teacher',
        status: 'active',
      });
      expect(user).toBeDefined();
      expect(user.email).toBe('test@test.com');
    });
  });

// ─── SECURITY EDGE CASES ─────────────────────────────────────────
// These test that authorization actually works

describe('Authorization security edge cases', () => {

  test('student cannot access admin endpoints', async () => {
    const adminToken = await createAdminAndLogin();

    // Create a student
    const programRes = await request(app)
      .post('/api/v1/admin/programs')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ name: 'BCA', type: 'semester' });

    const batchRes = await request(app)
      .post(`/api/v1/admin/programs/${programRes.body.data.program._id}/batches`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ name: 'BCA 2023', intakeYear: 2023 });

    const studentRes = await request(app)
      .post('/api/v1/admin/students')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        name: 'Test Student',
        email: 'student@test.com',
        rollNumber: 'BCA-001',
        programId: programRes.body.data.program._id,
        batchId: batchRes.body.data.batch._id,
      });

    // Update student password so we can login
    const studentUser = await User.findOne({ email: 'student@test.com' }).select('+password');
    studentUser.password = 'Student@123';
    studentUser.mustChangePassword = false;
    await studentUser.save();

    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: 'student@test.com', password: 'Student@123' });

    const studentToken = loginRes.body.data.token;

    // Try to access admin endpoint with student token
    const response = await request(app)
      .get('/api/v1/admin/teachers')
      .set('Authorization', `Bearer ${studentToken}`);

    expect(response.status).toBe(403);
  });

  test('teacher cannot access admin endpoints', async () => {
    const adminToken = await createAdminAndLogin();

    await request(app)
      .post('/api/v1/admin/teachers')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ name: 'Test Teacher', email: 'teacher@test.com', department: 'CS' });

    const teacherUser = await User.findOne({ email: 'teacher@test.com' }).select('+password');
    teacherUser.password = 'Teacher@123';
    teacherUser.mustChangePassword = false;
    await teacherUser.save();

    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: 'teacher@test.com', password: 'Teacher@123' });

    const teacherToken = loginRes.body.data.token;

    const response = await request(app)
      .post('/api/v1/admin/programs')
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({ name: 'BCA', type: 'semester' });

    expect(response.status).toBe(403);
  });

  test('suspended user cannot login', async () => {
    const adminToken = await createAdminAndLogin();

    await request(app)
      .post('/api/v1/admin/teachers')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ name: 'Test Teacher', email: 'teacher@test.com', department: 'CS' });

    const teacherUser = await User.findOne({ email: 'teacher@test.com' });
    teacherUser.status = 'suspended';
    await teacherUser.save();

    const response = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: 'teacher@test.com', password: 'anypassword' });

    expect(response.status).toBe(403);
  });

  test('expired or tampered token is rejected', async () => {
    const fakeToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImZha2VpZCIsInJvbGUiOiJhZG1pbiJ9.invalidsignature';

    const response = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${fakeToken}`);

    expect(response.status).toBe(401);
  });
});

// ─── DATA INTEGRITY EDGE CASES ───────────────────────────────────
// These test that the database constraints work correctly

describe('Data integrity edge cases', () => {

  test('cannot create two programs with same name', async () => {
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

  test('cannot create two batches with same program and intake year', async () => {
    const token = await createAdminAndLogin();

    const programRes = await request(app)
      .post('/api/v1/admin/programs')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'BCA', type: 'semester' });

    const programId = programRes.body.data.program._id;

    await request(app)
      .post(`/api/v1/admin/programs/${programId}/batches`)
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'BCA 2023', intakeYear: 2023 });

    const response = await request(app)
      .post(`/api/v1/admin/programs/${programId}/batches`)
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'BCA 2023 B', intakeYear: 2023 });

    expect(response.status).toBe(400);
    expect(response.body.error.code).toBe('DUPLICATE');
  });

  test('semester program always gets 8 terms', async () => {
    const token = await createAdminAndLogin();

    const response = await request(app)
      .post('/api/v1/admin/programs')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'BCA', type: 'semester' });

    expect(response.body.data.program.totalTerms).toBe(8);
  });

  test('year program always gets 4 terms', async () => {
    const token = await createAdminAndLogin();

    const response = await request(app)
      .post('/api/v1/admin/programs')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'BBS', type: 'year' });

    expect(response.body.data.program.totalTerms).toBe(4);
  });

  test('batch starts at term 1 by default', async () => {
    const token = await createAdminAndLogin();

    const programRes = await request(app)
      .post('/api/v1/admin/programs')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'BCA', type: 'semester' });

    const response = await request(app)
      .post(`/api/v1/admin/programs/${programRes.body.data.program._id}/batches`)
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'BCA 2023', intakeYear: 2023 });

    expect(response.body.data.batch.currentTerm).toBe(1);
  });

  test('cannot promote batch beyond final term', async () => {
    const token = await createAdminAndLogin();

    const programRes = await request(app)
      .post('/api/v1/admin/programs')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'BCA', type: 'semester' });

    const batchRes = await request(app)
      .post(`/api/v1/admin/programs/${programRes.body.data.program._id}/batches`)
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'BCA 2015', intakeYear: 2015 });

    // Set to final term directly in DB
    await Batch.findByIdAndUpdate(
      batchRes.body.data.batch._id,
      { currentTerm: 8 }
    );

    const response = await request(app)
      .post(`/api/v1/admin/programs/batches/${batchRes.body.data.batch._id}/promote`)
      .set('Authorization', `Bearer ${token}`);

    expect(response.status).toBe(400);
    expect(response.body.error.code).toBe('PROMOTION_LIMIT');
  });

  test('non-existent resource returns 404', async () => {
    const token = await createAdminAndLogin();
    const fakeId = new mongoose.Types.ObjectId();

    const response = await request(app)
      .patch(`/api/v1/admin/teachers/${fakeId}`)
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Updated Name' });

    expect(response.status).toBe(404);
  });
});