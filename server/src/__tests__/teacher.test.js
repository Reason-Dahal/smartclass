require('dotenv').config();
const request = require('supertest');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const app = require('../app');
const User = require('../models/User');
const Teacher = require('../models/Teacher');
const Student = require('../models/Student');
const Attendance = require('../models/Attendance');
const Assignment = require('../models/Assignment');
const Note = require('../models/Note');
const Marksheet = require('../models/Marksheet');

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

const setupTeacherAndCourse = async () => {
    const adminToken = await createAdminAndLogin();
  
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
      .send({
        name: 'Test Teacher',
        email: 'teacher@test.com',
        department: 'CS',
      });
  
    // Set known password for teacher
    const teacherUser = await User.findOne({ email: 'teacher@test.com' })
      .select('+password');
    teacherUser.password = 'Teacher@123';
    teacherUser.mustChangePassword = false;
    await teacherUser.save();
  
    // Login as teacher
    const teacherLoginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: 'teacher@test.com', password: 'Teacher@123' });
    const teacherToken = teacherLoginRes.body.data.token;
  
    // Get teacher profile
    const teacher = await Teacher.findOne();
  
    // Create course assigned to this teacher
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
  
    // Get student profile _id from database
    const student = await Student.findOne();
  
    // Enroll student using Student profile _id
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
      courseId: course._id,
      studentId: student._id.toString(),
      teacherId: teacher._id.toString(),
    };
  };

// ─── ATTENDANCE TESTS ────────────────────────────────────────────

describe('POST /api/v1/teacher/courses/:courseId/attendance', () => {

  test('should record attendance for enrolled students', async () => {
    const { teacherToken, courseId, studentId } =
      await setupTeacherAndCourse();

    const response = await request(app)
      .post(`/api/v1/teacher/courses/${courseId}/attendance`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        date: '2026-06-23',
        records: [{ studentId, status: 'present' }],
      });

    expect(response.status).toBe(200);
    expect(response.body.data.records).toHaveLength(1);

    const record = await Attendance.findOne({
      courseId,
      studentId,
    });
    expect(record.status).toBe('present');
  });

  test('should update existing attendance on re-submission (upsert)', async () => {
    const { teacherToken, courseId, studentId } =
      await setupTeacherAndCourse();

    // First submission
    await request(app)
      .post(`/api/v1/teacher/courses/${courseId}/attendance`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        date: '2026-06-23',
        records: [{ studentId, status: 'present' }],
      });

    // Second submission same date — should update not duplicate
    await request(app)
      .post(`/api/v1/teacher/courses/${courseId}/attendance`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        date: '2026-06-23',
        records: [{ studentId, status: 'absent' }],
      });

    const records = await Attendance.find({ courseId, studentId });
    expect(records).toHaveLength(1); // only one record
    expect(records[0].status).toBe('absent'); // updated to absent
  });

  test('should return 404 for course not belonging to teacher', async () => {
    const { adminToken, teacherToken } =
      await setupTeacherAndCourse();

    // Create another course not assigned to this teacher
    const anotherTeacherRes = await request(app)
      .post('/api/v1/admin/teachers')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        name: 'Another Teacher',
        email: 'another@test.com',
        department: 'Math',
      });

    const fakeId = new mongoose.Types.ObjectId();

    const response = await request(app)
      .post(`/api/v1/teacher/courses/${fakeId}/attendance`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        date: '2026-06-23',
        records: [{ studentId: fakeId, status: 'present' }],
      });

    expect(response.status).toBe(404);
  });

  test('should return 401 without token', async () => {
    const fakeId = new mongoose.Types.ObjectId();

    const response = await request(app)
      .post(`/api/v1/teacher/courses/${fakeId}/attendance`)
      .send({
        date: '2026-06-23',
        records: [],
      });

    expect(response.status).toBe(401);
  });

  test('should return 400 when date is missing', async () => {
    const { teacherToken, courseId, studentId } =
      await setupTeacherAndCourse();

    const response = await request(app)
      .post(`/api/v1/teacher/courses/${courseId}/attendance`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        records: [{ studentId, status: 'present' }],
      });

    expect(response.status).toBe(400);
  });

  test('should record multiple students in one submission', async () => {
    const { teacherToken, courseId, studentId } =
      await setupTeacherAndCourse();

    const studentId2 = new mongoose.Types.ObjectId().toString();

    const response = await request(app)
      .post(`/api/v1/teacher/courses/${courseId}/attendance`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        date: '2026-06-23',
        records: [
          { studentId, status: 'present' },
          { studentId: studentId2, status: 'absent' },
        ],
      });

    expect(response.status).toBe(200);
    expect(response.body.data.records).toHaveLength(2);
  });
});

describe('GET /api/v1/teacher/courses/:courseId/attendance', () => {

  test('should return attendance records for a course', async () => {
    const { teacherToken, courseId, studentId } =
      await setupTeacherAndCourse();

    await request(app)
      .post(`/api/v1/teacher/courses/${courseId}/attendance`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        date: '2026-06-23',
        records: [{ studentId, status: 'present' }],
      });

    const response = await request(app)
      .get(`/api/v1/teacher/courses/${courseId}/attendance`)
      .set('Authorization', `Bearer ${teacherToken}`);

    expect(response.status).toBe(200);
    expect(response.body.data.attendance).toHaveLength(1);
  });
});

// ─── ASSIGNMENT TESTS ────────────────────────────────────────────

describe('POST /api/v1/teacher/courses/:courseId/assignments', () => {

  test('should create assignment successfully', async () => {
    const { teacherToken, courseId } = await setupTeacherAndCourse();

    const response = await request(app)
      .post(`/api/v1/teacher/courses/${courseId}/assignments`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        title: 'Lab 1 — Linked Lists',
        description: 'Implement insertion and deletion',
        dueDate: '2026-07-01',
      });

    expect(response.status).toBe(201);
    expect(response.body.data.assignment.title).toBe('Lab 1 — Linked Lists');

    const assignment = await Assignment.findOne({ courseId });
    expect(assignment).not.toBeNull();
    expect(assignment.title).toBe('Lab 1 — Linked Lists');
  });

  test('should return 400 when title is missing', async () => {
    const { teacherToken, courseId } = await setupTeacherAndCourse();

    const response = await request(app)
      .post(`/api/v1/teacher/courses/${courseId}/assignments`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        description: 'Some description',
        dueDate: '2026-07-01',
      });

    expect(response.status).toBe(400);
  });

  test('should return 400 when dueDate is missing', async () => {
    const { teacherToken, courseId } = await setupTeacherAndCourse();

    const response = await request(app)
      .post(`/api/v1/teacher/courses/${courseId}/assignments`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        title: 'Lab 1',
        description: 'Some description',
      });

    expect(response.status).toBe(400);
  });

  test('should return 403 when student tries to create assignment', async () => {
    const { courseId, adminToken } = await setupTeacherAndCourse();

    // Set known password for student
    const studentUser = await User.findOne({ email: 'student@test.com' })
      .select('+password');
    studentUser.password = 'Student@123';
    studentUser.mustChangePassword = false;
    await studentUser.save();

    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: 'student@test.com', password: 'Student@123' });

    const studentToken = loginRes.body.data.token;

    const response = await request(app)
      .post(`/api/v1/teacher/courses/${courseId}/assignments`)
      .set('Authorization', `Bearer ${studentToken}`)
      .send({
        title: 'Fake Assignment',
        dueDate: '2026-07-01',
      });

    expect(response.status).toBe(403);
  });

  test('creating assignment should notify enrolled students', async () => {
    const { teacherToken, courseId } = await setupTeacherAndCourse();
  
    const assignRes = await request(app)
      .post(`/api/v1/teacher/courses/${courseId}/assignments`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        title: 'Lab 1',
        description: 'Linked lists',
        dueDate: '2026-07-01',
      });
  
   
  
    const Enrollment = require('../models/Enrollment');
    const enrollments = await Enrollment.find({ courseId });
    
  
    const Notification = require('../models/Notification');
    const notifications = await Notification.find({ type: 'assignment' });
    
  
    expect(notifications.length).toBeGreaterThan(0);
    expect(notifications[0].message).toContain('Lab 1');
  });
});

// ─── NOTES TESTS ─────────────────────────────────────────────────

describe('POST /api/v1/teacher/courses/:courseId/notes', () => {

  test('should upload note successfully', async () => {
    const { teacherToken, courseId } = await setupTeacherAndCourse();

    const response = await request(app)
      .post(`/api/v1/teacher/courses/${courseId}/notes`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        title: 'Unit 1 Notes',
        fileUrl: 'https://example.com/unit1.pdf',
      });

    expect(response.status).toBe(201);
    expect(response.body.data.note.title).toBe('Unit 1 Notes');

    const note = await Note.findOne({ courseId });
    expect(note).not.toBeNull();
    expect(note.fileUrl).toBe('https://example.com/unit1.pdf');
  });

  test('should return 400 when fileUrl is missing', async () => {
    const { teacherToken, courseId } = await setupTeacherAndCourse();

    const response = await request(app)
      .post(`/api/v1/teacher/courses/${courseId}/notes`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({ title: 'Unit 1 Notes' });

    expect(response.status).toBe(400);
  });

  test('uploading note should notify enrolled students', async () => {
    const { teacherToken, courseId } = await setupTeacherAndCourse();

    await request(app)
      .post(`/api/v1/teacher/courses/${courseId}/notes`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        title: 'Unit 1 Notes',
        fileUrl: 'https://example.com/unit1.pdf',
      });

    const Notification = require('../models/Notification');
    const notifications = await Notification.find({ type: 'note' });
    expect(notifications.length).toBeGreaterThan(0);
  });

  test('should soft delete note', async () => {
    const { teacherToken, courseId } = await setupTeacherAndCourse();

    const createRes = await request(app)
      .post(`/api/v1/teacher/courses/${courseId}/notes`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        title: 'Unit 1 Notes',
        fileUrl: 'https://example.com/unit1.pdf',
      });

    const noteId = createRes.body.data.note._id;

    const deleteRes = await request(app)
      .delete(`/api/v1/teacher/notes/${noteId}`)
      .set('Authorization', `Bearer ${teacherToken}`);

    expect(deleteRes.status).toBe(200);

    // Note should still exist in DB but isActive = false
    const note = await Note.findById(noteId);
    expect(note).not.toBeNull();
    expect(note.isActive).toBe(false);
  });
});

// ─── MARKSHEET TESTS ─────────────────────────────────────────────

describe('POST /api/v1/teacher/courses/:courseId/marksheets', () => {

  test('should upload marksheet successfully', async () => {
    const { teacherToken, courseId, studentId } =
      await setupTeacherAndCourse();

    const response = await request(app)
      .post(`/api/v1/teacher/courses/${courseId}/marksheets`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        studentId,
        term: 1,
        internalExamMarks: 35,
        internalExamTotalMarks: 50,
        teacherEvaluationScore: 80,
      });

    expect(response.status).toBe(200);

    const marksheet = await Marksheet.findOne({ courseId, studentId });
    expect(marksheet).not.toBeNull();
    expect(marksheet.internalExamMarks).toBe(35);
    expect(marksheet.teacherEvaluationScore).toBe(80);
  });

  test('should update existing marksheet on re-upload (upsert)', async () => {
    const { teacherToken, courseId, studentId } =
      await setupTeacherAndCourse();

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

    // Re-upload with corrected marks
    await request(app)
      .post(`/api/v1/teacher/courses/${courseId}/marksheets`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        studentId,
        term: 1,
        internalExamMarks: 40, // corrected
        internalExamTotalMarks: 50,
        teacherEvaluationScore: 85,
      });

    const marksheets = await Marksheet.find({ courseId, studentId, term: 1 });
    expect(marksheets).toHaveLength(1); // only one record
    expect(marksheets[0].internalExamMarks).toBe(40); // updated
  });

  test('should return 400 when required fields are missing', async () => {
    const { teacherToken, courseId, studentId } =
      await setupTeacherAndCourse();

    const response = await request(app)
      .post(`/api/v1/teacher/courses/${courseId}/marksheets`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        studentId,
        term: 1,
        // missing internalExamMarks, internalExamTotalMarks, teacherEvaluationScore
      });

    expect(response.status).toBe(400);
  });
});

// ─── EVALUATION TOGGLE TESTS ─────────────────────────────────────

describe('PATCH /api/v1/courses/teacher/:id/evaluation', () => {

  test('should enable evaluation indicator for course', async () => {
    const { teacherToken, courseId } = await setupTeacherAndCourse();

    const response = await request(app)
      .patch(`/api/v1/courses/teacher/${courseId}/evaluation`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({ evaluationEnabled: true });

    expect(response.status).toBe(200);

    const Course = require('../models/Course');
    const course = await Course.findById(courseId);
    expect(course.evaluationEnabled).toBe(true);
  });

  test('should disable evaluation indicator for course', async () => {
    const { teacherToken, courseId } = await setupTeacherAndCourse();

    // First enable
    await request(app)
      .patch(`/api/v1/courses/teacher/${courseId}/evaluation`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({ evaluationEnabled: true });

    // Then disable
    const response = await request(app)
      .patch(`/api/v1/courses/teacher/${courseId}/evaluation`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({ evaluationEnabled: false });

    expect(response.status).toBe(200);

    const Course = require('../models/Course');
    const course = await Course.findById(courseId);
    expect(course.evaluationEnabled).toBe(false);
  });
});