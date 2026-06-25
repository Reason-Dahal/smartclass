require('dotenv').config();
const request = require('supertest');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const app = require('../app');
const User = require('../models/User');

let mongoServer;

// ─── SETUP ───────────────────────────────────────────────────────

beforeAll(async () => {
  mongoServer = await MongoMemoryServer.create();
  await mongoose.connect(mongoServer.getUri());
});

afterEach(async () => {
  // Clear all collections after each test
  const collections = mongoose.connection.collections;
  for (const key in collections) {
    await collections[key].deleteMany({});
  }
});

afterAll(async () => {
  await mongoose.disconnect();
  await mongoServer.stop();
});

// ─── HELPER ──────────────────────────────────────────────────────

const createAdminUser = async () => {
  return await User.create({
    name: 'Test Admin',
    email: 'admin@test.com',
    password: 'Admin@123',
    role: 'admin',
    status: 'active',
    mustChangePassword: false,
  });
};

// ─── TESTS ───────────────────────────────────────────────────────

describe('POST /api/v1/auth/login', () => {

    test('should login successfully with valid credentials', async () => {
        await createAdminUser();
      
        const response = await request(app)
          .post('/api/v1/auth/login')
          .send({ email: 'admin@test.com', password: 'Admin@123' });
      
        
      
        expect(response.status).toBe(200);
        expect(response.body.success).toBe(true);
        expect(response.body.data.token).toBeDefined();
        expect(response.body.data.user.role).toBe('admin');
        expect(response.body.data.user.email).toBe('admin@test.com');
      });
  test('should return 401 with wrong password', async () => {
    await createAdminUser();

    const response = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: 'admin@test.com', password: 'WrongPassword@1' });

    expect(response.status).toBe(401);
    expect(response.body.success).toBe(false);
    expect(response.body.error.code).toBe('INVALID_CREDENTIALS');
  });

  test('should return 401 with wrong email', async () => {
    const response = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: 'nobody@test.com', password: 'Admin@123' });

    expect(response.status).toBe(401);
    expect(response.body.success).toBe(false);
  });

  test('should return 400 when email is missing', async () => {
    const response = await request(app)
      .post('/api/v1/auth/login')
      .send({ password: 'Admin@123' });

    expect(response.status).toBe(400);
    expect(response.body.success).toBe(false);
  });

  test('should return 400 when password is missing', async () => {
    const response = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: 'admin@test.com' });

    expect(response.status).toBe(400);
    expect(response.body.success).toBe(false);
  });

  test('should not return password in response', async () => {
    await createAdminUser();

    const response = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: 'admin@test.com', password: 'Admin@123' });

    expect(response.body.data.user.password).toBeUndefined();
  });

  test('should return 403 when account is suspended', async () => {
    await User.create({
      name: 'Suspended User',
      email: 'suspended@test.com',
      password: 'Admin@123',
      role: 'teacher',
      status: 'suspended',
      mustChangePassword: false,
    });

    const response = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: 'suspended@test.com', password: 'Admin@123' });

    expect(response.status).toBe(403);
    expect(response.body.error.code).toBe('ACCOUNT_SUSPENDED');
  });

  test('should include mustChangePassword in response', async () => {
    await User.create({
      name: 'New Teacher',
      email: 'newteacher@test.com',
      password: 'Admin@123',
      role: 'teacher',
      status: 'active',
      mustChangePassword: true,
    });

    const response = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: 'newteacher@test.com', password: 'Admin@123' });

    expect(response.status).toBe(200);
    expect(response.body.data.user.mustChangePassword).toBe(true);
  });
});

describe('GET /api/v1/auth/me', () => {

  test('should return current user when authenticated', async () => {
    await createAdminUser();

    // First login to get token
    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: 'admin@test.com', password: 'Admin@123' });

    const token = loginRes.body.data.token;

    // Then call /me with token
    const response = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${token}`);

    expect(response.status).toBe(200);
    expect(response.body.data.user.email).toBe('admin@test.com');
  });

  test('should return 401 without token', async () => {
    const response = await request(app).get('/api/v1/auth/me');
    expect(response.status).toBe(401);
  });

  test('should return 401 with invalid token', async () => {
    const response = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', 'Bearer invalidtoken123');
    expect(response.status).toBe(401);
  });
});