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
└── client/                  ← Flutter application (in progress)
```

## Getting Started

### Prerequisites

- Node.js v18 or above
- MongoDB Atlas account
- Git

### Backend Setup

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/smartclass.git
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

## Environment Variables

See `.env.example` for the full list.

| Variable | Status | Notes |
|---|---|---|
| `PORT` | Ready | Defaults to 5000 |
| `MONGODB_URI` | Required now | MongoDB Atlas connection string |
| `JWT_SECRET` | Required now | Any long random string |
| `JWT_EXPIRES_IN` | Required now | e.g. 7d |
| `CLOUDINARY_CLOUD_NAME` | Add later | When building file uploads in Flutter |
| `CLOUDINARY_API_KEY` | Add later | When building file uploads in Flutter |
| `CLOUDINARY_API_SECRET` | Add later | When building file uploads in Flutter |
| `EMAIL_HOST` | Add later | When configuring real email delivery |
| `EMAIL_PORT` | Add later | When configuring real email delivery |
| `EMAIL_USER` | Add later | When configuring real email delivery |
| `EMAIL_PASS` | Add later | When configuring real email delivery |

## Available Scripts

Run all scripts from inside the `server/` folder:

```bash
npm run dev      # Start development server with nodemon
npm run start    # Start production server
npm run seed     # Create the Super Admin account (run once)
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

## Documentation

| Document | Description |
|---|---|
| SmartClass_SRS_v1.1.docx | Software Requirements Specification |
| SmartClass_Phase2_Design.docx | System Design — Architecture, Schema, API, Wireframes |
| SmartClass_Phase3_Part1.docx | Implementation — Foundation, Models, Auth, Admin |
| SmartClass_Phase3_Part2.docx | Implementation — Academic Modules, Complete API Reference |

## SDLC Progress

- [x] Phase 1 — Requirement Analysis (SRS v1.1)
- [x] Phase 2 — System Design
- [x] Phase 3 — Implementation (Backend complete)
- [ ] Phase 3 — Implementation (Flutter frontend — in progress)
- [ ] Phase 4 — Testing
- [ ] Phase 5 — Deployment
- [ ] Phase 6 — Maintenance