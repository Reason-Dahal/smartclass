# SmartClass

A cross-platform academic management system for universities, built with Flutter, Node.js, and MongoDB.

## Project Overview

SmartClass manages academic operations — attendance, assignments, notes, marksheets, and student evaluation — for a single university with multiple faculties/programs. It supports three roles: Student, Teacher, and Super Admin.

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile / Desktop / Web | Flutter (single codebase) |
| Backend API | Node.js + Express |
| Database | MongoDB Atlas |
| File Storage | Cloudinary |
| Authentication | JWT + bcrypt |

## Project Structure

```
smartclass/
├── server/                  ← Node.js + Express REST API
│   ├── src/
│   │   ├── config/          ← DB connection, seed, reset scripts
│   │   ├── models/          ← 15 Mongoose models
│   │   ├── controllers/     ← Business logic
│   │   ├── routes/          ← URL definitions
│   │   ├── middleware/      ← JWT auth, RBAC
│   │   └── utils/           ← JWT, bcrypt, email, password generator
│   ├── .env.example         ← Environment variable template
│   └── server.js            ← Entry point
└── client/                  ← Flutter application
    └── lib/
        ├── core/            ← Shared infrastructure
        ├── features/        ← Auth, Student, Teacher, Admin modules
        └── shared/          ← Theme, reusable widgets
```

## Getting Started

### Prerequisites

- Node.js v18 or above
- Flutter 3.41.9 or above
- MongoDB Atlas account
- Git

### Backend Setup

```bash
# Clone the repository
git clone https://github.com/Reason-Dahal/smartclass.git
cd smartclass/server

# Install dependencies
npm install

# Create environment file
cp .env.example .env
# Fill in your values in .env

# Seed the Super Admin account (run once)
npm run seed

# Start development server
npm run dev
```

Server runs on `http://localhost:5000`

### Flutter Setup

```bash
cd smartclass/client

# Install dependencies
flutter pub get

# Run on connected device
flutter run
```

## Environment Variables

See `.env.example` for the full list.

| Variable | Status | Notes |
|---|---|---|
| `PORT` | Ready | Defaults to 5000 |
| `MONGODB_URI` | Required | MongoDB Atlas connection string |
| `JWT_SECRET` | Required | Any long random string |
| `JWT_EXPIRES_IN` | Required | e.g. 7d |
| `CLOUDINARY_CLOUD_NAME` | Required | From Cloudinary dashboard |
| `CLOUDINARY_API_KEY` | Required | From Cloudinary dashboard |
| `CLOUDINARY_API_SECRET` | Required | From Cloudinary dashboard |
| `EMAIL_HOST` | Required | smtp.gmail.com |
| `EMAIL_PORT` | Required | 587 |
| `EMAIL_USER` | Required | Gmail address |
| `EMAIL_PASS` | Required | Gmail App Password (16 chars) |

## Available Scripts

Run all scripts from inside the `server/` folder:

```bash
npm run dev      # Start development server with nodemon
npm run start    # Start production server
npm run seed     # Create the Super Admin account (run once)
npm run test     # Run all backend tests
```

## API Base URL

`http://localhost:5000/api/v1`

All endpoints require `Authorization: Bearer <token>` header except `POST /auth/login`.

## Roles

| Role | Access |
|---|---|
| `admin` | Full system access — users, programs, courses, overrides, reports |
| `teacher` | Own courses — attendance, assignments, notes, marksheets |
| `student` | Own data — attendance, assignments, notes, results, evaluation |

## Default Admin Credentials

Created by the seed script. **Change immediately after first login.**

```
Email:    admin@smartclass.com
Password: Admin@123
```

## Testing

Backend integration tests use Jest + Supertest + MongoDB Memory Server.

```bash
cd server
npm test
```

### Test Coverage

| Test Suite | Tests | Coverage |
|---|---|---|
| auth.test.js | 11 | Login, token validation, getMe |
| admin.test.js | 19 | Teacher/student management, programs, status |
| courses.test.js | 9 | Batches, courses, enrollment |
| teacher.test.js | 21 | Attendance, assignments, notes, marksheets |
| student.test.js | 20 | Attendance %, submissions, notes, marks, notifications |
| **Total** | **80** | **All passing** |

## Documentation

| Document | Description |
|---|---|
| SmartClass_SRS_v1.1.docx | Software Requirements Specification |
| SmartClass_Phase2_Design.docx | System Design — Architecture, Schema, API, Wireframes |
| SmartClass_Phase3_Part1.docx | Implementation — Foundation, Models, Auth, Admin (38 pages) |
| SmartClass_Phase3_Part2.docx | Implementation — Academic Modules, Complete API Reference (25 pages) |
| SmartClass_Phase3_Part3.docx | Implementation — Flutter Frontend, State Management, Data Flows (41 pages) |
| SmartClass_Phase3_Addendum.docx | Features Added During Development (20 pages) |

## SDLC Progress

- [x] Phase 1 — Requirement Analysis (SRS v1.1)
- [x] Phase 2 — System Design
- [x] Phase 3 — Implementation (Backend complete)
- [x] Phase 3 — Implementation (Flutter frontend complete)
- [x] Phase 4 — Testing (Backend regression tests — 80 passing)
- [ ] Phase 4 — Testing (Edge case tests + Flutter widget tests)
- [ ] Phase 5 — Deployment
- [ ] Phase 6 — Maintenance