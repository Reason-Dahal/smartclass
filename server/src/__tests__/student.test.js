require('dotenv').config();
const request = require('supertest');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const app = require('../app');
const User = require('../models/User');
const Teacher = require('../models/Teacher');
const Student = require('../models/Student');
const Attendance = require('../models/Attendance');
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

const setupFullEnvironment = async () => {
  // Create admin
  await User.create({
    name: 'Test Admin',
    email: 'admin@test.com',
    password: 'Admin@123',
    role: 'admin',
    status: 'active',
    mustChangePassword: false,
  });
  const adminLoginRes = await request(app)
    .post('/api/v1/auth/login')
    .send({ email: 'admin@test.com', password: 'Admin@123' });
  const adminToken = adminLoginRes.body.data.token;

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

  // Create teacher
  await request(app)
    .post('/api/v1/admin/teachers')
    .set('Authorization', `Bearer ${adminToken}`)
    .send({ name: 'Test Teacher', email: 'teacher@test.com', department: 'CS' });

  const teacherUser = await User.findOne({ email: 'teacher@test.com' })
    .select('+password');
  teacherUser.password = 'Teacher@123';
  teacherUser.mustChangePassword = false;
  await teacherUser.save();

  const teacherLoginRes = await request(app)
    .post('/api/v1/auth/login')
    .send({ email: 'teacher@test.com', password: 'Teacher@123' });
  const teacherToken = teacherLoginRes.body.data.token;

  const teacher = await Teacher.findOne();

  // Create course
  const courseRes = await request(app)
    .post('/api/v1/courses')
    .set('Authorization', `Bearer ${adminToken}`)
    .send({
      programId: program._id,
      teacherId: teacher._id.toString(),
      subjectName: 'Data Structures',
      term: 1,
      isElective: false,
    });
  const course = courseRes.body.data.course;

  // Create student
  await request(app)
    .post('/api/v1/admin/students')
    .set('Authorization', `Bearer ${adminToken}`)
    .send({
      name: 'Test Student',
      email: 'student@test.com',
      rollNumber: 'BCA-001',
      programId: program._id,
      batchId: batch._id,
    });

  const studentUser = await User.findOne({ email: 'student@test.com' })
    .select('+password');
  studentUser.password = 'Student@123';
  studentUser.mustChangePassword = false;
  await studentUser.save();

  const studentLoginRes = await request(app)
    .post('/api/v1/auth/login')
    .send({ email: 'student@test.com', password: 'Student@123' });
  const studentToken = studentLoginRes.body.data.token;

  const student = await Student.findOne();

  // Enroll student in course
  await request(app)
    .post('/api/v1/admin/enroll')
    .set('Authorization', `Bearer ${adminToken}`)
    .send({
      studentId: student._id.toString(),
      courseId: course._id,
    });

  return {
    adminToken,
    teacherToken,
    studentToken,
    courseId: course._id,
    studentId: student._id.toString(),
    teacherId: teacher._id.toString(),
    programId: program._id,
    batchId: batch._id,
  };
};

// ─── ATTENDANCE TESTS ────────────────────────────────────────────

describe('GET /api/v1/student/attendance', () => {

  test('should return attendance summary for enrolled courses', async () => {
    const { teacherToken, studentToken, courseId, studentId } =
      await setupFullEnvironment();

    // Teacher takes attendance
    await request(app)
      .post(`/api/v1/teacher/courses/${courseId}/attendance`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        date: '2026-06-23',
        records: [{ studentId, status: 'present' }],
      });

    const response = await request(app)
      .get('/api/v1/student/attendance')
      .set('Authorization', `Bearer ${studentToken}`);

    expect(response.status).toBe(200);
    expect(response.body.data.summary).toHaveLength(1);
    expect(response.body.data.summary[0].present).toBe(1);
    expect(response.body.data.summary[0].attendancePercentage).toBe('100.00');
  });

  test('should return empty summary when no attendance recorded', async () => {
    const { studentToken } = await setupFullEnvironment();

    const response = await request(app)
      .get('/api/v1/student/attendance')
      .set('Authorization', `Bearer ${studentToken}`);

    expect(response.status).toBe(200);
    expect(response.body.data.summary).toHaveLength(0);
  });

  test('should calculate correct attendance percentage', async () => {
    const { teacherToken, studentToken, courseId, studentId } =
      await setupFullEnvironment();

    // 2 present, 1 absent = 66.67%
    await request(app)
      .post(`/api/v1/teacher/courses/${courseId}/attendance`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        date: '2026-06-21',
        records: [{ studentId, status: 'present' }],
      });

    await request(app)
      .post(`/api/v1/teacher/courses/${courseId}/attendance`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        date: '2026-06-22',
        records: [{ studentId, status: 'present' }],
      });

    await request(app)
      .post(`/api/v1/teacher/courses/${courseId}/attendance`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        date: '2026-06-23',
        records: [{ studentId, status: 'absent' }],
      });

    const response = await request(app)
      .get('/api/v1/student/attendance')
      .set('Authorization', `Bearer ${studentToken}`);

    expect(response.status).toBe(200);
    expect(response.body.data.summary[0].present).toBe(2);
    expect(response.body.data.summary[0].absent).toBe(1);
    expect(response.body.data.summary[0].totalClasses).toBe(3);
    expect(response.body.data.summary[0].attendancePercentage).toBe('66.67');
  });

  test('should return 401 without token', async () => {
    const response = await request(app)
      .get('/api/v1/student/attendance');
    expect(response.status).toBe(401);
  });

  test('should return 403 when teacher tries to access student endpoint', async () => {
    const { teacherToken } = await setupFullEnvironment();

    const response = await request(app)
      .get('/api/v1/student/attendance')
      .set('Authorization', `Bearer ${teacherToken}`);

    expect(response.status).toBe(403);
  });
});

// ─── ASSIGNMENTS TESTS ───────────────────────────────────────────

describe('GET /api/v1/student/assignments', () => {

  test('should return assignments for enrolled courses', async () => {
    const { teacherToken, studentToken, courseId } =
      await setupFullEnvironment();

    await request(app)
      .post(`/api/v1/teacher/courses/${courseId}/assignments`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        title: 'Lab 1',
        description: 'Linked lists',
        dueDate: '2026-07-01',
      });

    const response = await request(app)
      .get('/api/v1/student/assignments')
      .set('Authorization', `Bearer ${studentToken}`);

    expect(response.status).toBe(200);
    expect(response.body.data.assignments).toHaveLength(1);
    expect(response.body.data.assignments[0].title).toBe('Lab 1');
    expect(response.body.data.assignments[0].isSubmitted).toBe(false);
  });

  test('should mark assignment as past due correctly', async () => {
    const { teacherToken, studentToken, courseId } =
      await setupFullEnvironment();

    await request(app)
      .post(`/api/v1/teacher/courses/${courseId}/assignments`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        title: 'Past Assignment',
        description: 'Old one',
        dueDate: '2020-01-01', // past date
      });

    const response = await request(app)
      .get('/api/v1/student/assignments')
      .set('Authorization', `Bearer ${studentToken}`);

    expect(response.status).toBe(200);
    expect(response.body.data.assignments[0].isPastDue).toBe(true);
  });

  test('should return empty list when no assignments exist', async () => {
    const { studentToken } = await setupFullEnvironment();

    const response = await request(app)
      .get('/api/v1/student/assignments')
      .set('Authorization', `Bearer ${studentToken}`);

    expect(response.status).toBe(200);
    expect(response.body.data.assignments).toHaveLength(0);
  });
});

// ─── ASSIGNMENT SUBMISSION TESTS ─────────────────────────────────

describe('POST /api/v1/student/assignments/:id/submit', () => {

  test('should submit assignment successfully', async () => {
    const { teacherToken, studentToken, courseId } =
      await setupFullEnvironment();

    const assignRes = await request(app)
      .post(`/api/v1/teacher/courses/${courseId}/assignments`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        title: 'Lab 1',
        description: 'Linked lists',
        dueDate: '2026-07-01',
      });

    const assignmentId = assignRes.body.data.assignment._id;

    const response = await request(app)
      .post(`/api/v1/student/assignments/${assignmentId}/submit`)
      .set('Authorization', `Bearer ${studentToken}`)
      .send({ fileUrl: 'https://cloudinary.com/test.pdf' });

    expect(response.status).toBe(200);
    expect(response.body.data.message).toContain('submitted');
  });

  test('should mark submission as on-time before due date', async () => {
    const { teacherToken, studentToken, courseId } =
      await setupFullEnvironment();

    const assignRes = await request(app)
      .post(`/api/v1/teacher/courses/${courseId}/assignments`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        title: 'Lab 1',
        dueDate: '2026-12-31', // future date
      });

    const assignmentId = assignRes.body.data.assignment._id;

    await request(app)
      .post(`/api/v1/student/assignments/${assignmentId}/submit`)
      .set('Authorization', `Bearer ${studentToken}`)
      .send({ fileUrl: 'https://cloudinary.com/test.pdf' });

    const Submission = require('../models/Submission');
    const submission = await Submission.findOne({ assignmentId });
    expect(submission.status).toBe('on-time');
  });

  test('should mark submission as late after due date', async () => {
    const { teacherToken, studentToken, courseId } =
      await setupFullEnvironment();

    const assignRes = await request(app)
      .post(`/api/v1/teacher/courses/${courseId}/assignments`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        title: 'Lab 1',
        dueDate: '2020-01-01', // past date
      });

    const assignmentId = assignRes.body.data.assignment._id;

    await request(app)
      .post(`/api/v1/student/assignments/${assignmentId}/submit`)
      .set('Authorization', `Bearer ${studentToken}`)
      .send({ fileUrl: 'https://cloudinary.com/test.pdf' });

    const Submission = require('../models/Submission');
    const submission = await Submission.findOne({ assignmentId });
    expect(submission.status).toBe('late');
  });

  test('should return 403 when student not enrolled in course', async () => {
    const { teacherToken, courseId, adminToken } =
      await setupFullEnvironment();

    // Create another student not enrolled
    await request(app)
      .post('/api/v1/admin/students')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        name: 'Other Student',
        email: 'other@test.com',
        rollNumber: 'BCA-002',
        programId: (await Student.findOne()).programId,
        batchId: (await Student.findOne()).batchId,
      });

    const otherUser = await User.findOne({ email: 'other@test.com' })
      .select('+password');
    otherUser.password = 'Student@123';
    otherUser.mustChangePassword = false;
    await otherUser.save();

    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: 'other@test.com', password: 'Student@123' });

    const otherToken = loginRes.body.data.token;

    const assignRes = await request(app)
      .post(`/api/v1/teacher/courses/${courseId}/assignments`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({ title: 'Lab 1', dueDate: '2026-07-01' });

    const response = await request(app)
      .post(`/api/v1/student/assignments/${assignRes.body.data.assignment._id}/submit`)
      .set('Authorization', `Bearer ${otherToken}`)
      .send({ fileUrl: 'https://cloudinary.com/test.pdf' });

    expect(response.status).toBe(403);
  });
});

// ─── NOTES TESTS ─────────────────────────────────────────────────

describe('GET /api/v1/student/notes', () => {

  test('should return notes for enrolled courses', async () => {
    const { teacherToken, studentToken, courseId } =
      await setupFullEnvironment();

    await request(app)
      .post(`/api/v1/teacher/courses/${courseId}/notes`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        title: 'Unit 1 Notes',
        fileUrl: 'https://example.com/unit1.pdf',
      });

    const response = await request(app)
      .get('/api/v1/student/notes')
      .set('Authorization', `Bearer ${studentToken}`);

    expect(response.status).toBe(200);
    expect(response.body.data.notes).toHaveLength(1);
    expect(response.body.data.notes[0].title).toBe('Unit 1 Notes');
  });

  test('should not show deleted notes', async () => {
    const { teacherToken, studentToken, courseId } =
      await setupFullEnvironment();

    const noteRes = await request(app)
      .post(`/api/v1/teacher/courses/${courseId}/notes`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        title: 'Unit 1 Notes',
        fileUrl: 'https://example.com/unit1.pdf',
      });

    // Delete the note
    await request(app)
      .delete(`/api/v1/teacher/notes/${noteRes.body.data.note._id}`)
      .set('Authorization', `Bearer ${teacherToken}`);

    const response = await request(app)
      .get('/api/v1/student/notes')
      .set('Authorization', `Bearer ${studentToken}`);

    expect(response.status).toBe(200);
    expect(response.body.data.notes).toHaveLength(0);
  });
});

// ─── MARKSHEETS TESTS ────────────────────────────────────────────

describe('GET /api/v1/student/marksheets', () => {

  test('should return marksheets for student', async () => {
    const { teacherToken, studentToken, courseId, studentId } =
      await setupFullEnvironment();

    await request(app)
      .post(`/api/v1/teacher/courses/${courseId}/marksheets`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        studentId,
        term: 1,
        internalExamMarks: 35,
        internalExamTotalMarks: 50,
        teacherEvaluationScore: 80,
      });

    const response = await request(app)
      .get('/api/v1/student/marksheets')
      .set('Authorization', `Bearer ${studentToken}`);

    expect(response.status).toBe(200);
    expect(response.body.data.marksheets).toHaveLength(1);
    expect(response.body.data.marksheets[0].internalExamMarks).toBe(35);
    expect(response.body.data.marksheets[0].teacherEvaluationScore).toBe(80);
  });

  test('should return empty list when no marksheets exist', async () => {
    const { studentToken } = await setupFullEnvironment();

    const response = await request(app)
      .get('/api/v1/student/marksheets')
      .set('Authorization', `Bearer ${studentToken}`);

    expect(response.status).toBe(200);
    expect(response.body.data.marksheets).toHaveLength(0);
  });
});

// ─── NOTIFICATIONS TESTS ─────────────────────────────────────────

describe('GET /api/v1/student/notifications', () => {

  test('should return notifications for student', async () => {
    const { teacherToken, studentToken, courseId } =
      await setupFullEnvironment();

    // Create assignment — triggers notification
    await request(app)
      .post(`/api/v1/teacher/courses/${courseId}/assignments`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        title: 'Lab 1',
        dueDate: '2026-07-01',
      });

    const response = await request(app)
      .get('/api/v1/student/notifications')
      .set('Authorization', `Bearer ${studentToken}`);

    expect(response.status).toBe(200);
    expect(response.body.data.notifications.length).toBeGreaterThan(0);
    expect(response.body.data.unreadCount).toBeGreaterThan(0);
  });

  test('should return empty notifications for new student', async () => {
    const { studentToken } = await setupFullEnvironment();

    const response = await request(app)
      .get('/api/v1/student/notifications')
      .set('Authorization', `Bearer ${studentToken}`);

    expect(response.status).toBe(200);
    expect(response.body.data.notifications).toHaveLength(0);
    expect(response.body.data.unreadCount).toBe(0);
  });
});

// ─── COURSES TESTS ───────────────────────────────────────────────

describe('GET /api/v1/courses/student/my-courses', () => {

  test('should return enrolled courses for student', async () => {
    const { studentToken } = await setupFullEnvironment();

    const response = await request(app)
      .get('/api/v1/courses/student/my-courses')
      .set('Authorization', `Bearer ${studentToken}`);

    expect(response.status).toBe(200);
    expect(response.body.data.courses).toHaveLength(1);
    expect(response.body.data.courses[0].course.subjectName)
      .toBe('Data Structures');
  });

  test('should return 401 without token', async () => {
    const response = await request(app)
      .get('/api/v1/courses/student/my-courses');
    expect(response.status).toBe(401);
  });
});