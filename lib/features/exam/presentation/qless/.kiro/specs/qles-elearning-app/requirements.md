# Requirements Document

## Introduction

Q-Les is a premium Hybrid E-Learning mobile application built with Flutter, integrating Firebase (authentication and real-time data) and a Laravel REST API backend. The app features a Modern Glassmorphism design system using a Clean White & Cobalt Blue color palette with Plus Jakarta Sans typography. It supports two user roles — Teacher and Student — each with a dedicated dashboard experience, plus a proctored exam interface for Semester 2.

## Glossary

- **App**: The Q-Les Flutter mobile application
- **Auth_Screen**: The unified login/register screen with role selection
- **Student_Dashboard**: The learning-mode interface for students
- **Teacher_Dashboard**: The management-mode interface for teachers
- **Exam_Interface**: The proctored exam screen for Semester 2
- **Firebase**: Google's backend platform used for authentication and real-time data
- **Laravel_API**: The RESTful backend service built with Laravel
- **Auth_Service**: The module responsible for authentication operations
- **Class_Service**: The module responsible for fetching and managing class data from Laravel_API
- **Exam_Service**: The module responsible for exam data, countdowns, and submission via Firebase
- **Anti_Cheat_Monitor**: The module that detects and logs exam integrity violations
- **Audit_Log_Service**: The module that records and streams real-time classroom activity logs
- **Design_System**: The shared UI component library implementing Modern Glassmorphism style
- **Role_Toggle**: The UI control allowing users to select Teacher or Student role at login
- **Glass_Card**: A translucent card widget with soft shadow, part of the Design_System
- **Cobalt_Blue**: The primary brand color (#0047AB) used for action elements
- **User**: Any authenticated person using the App (Teacher or Student)

---

## Requirements

### Requirement 1: Design System & Typography

**User Story:** As a User, I want a consistent, premium visual experience, so that the app feels professional and easy to navigate.

#### Acceptance Criteria

1. THE Design_System SHALL apply Plus Jakarta Sans as the sole typeface across all screens.
2. THE Design_System SHALL render Glass_Card components using a translucent white background with a blur effect and a soft drop shadow of 8dp radius.
3. THE Design_System SHALL use Cobalt_Blue (#0047AB) as the primary color for all action buttons, toggles, and interactive highlights.
4. THE Design_System SHALL render all screens on a pristine white-to-light-grey (#F5F7FA) background gradient.
5. THE Design_System SHALL provide high-contrast action buttons with a minimum contrast ratio of 4.5:1 between button text and button background.

---

### Requirement 2: Unified Authentication Screen

**User Story:** As a User, I want to log in or register with a single screen that supports role selection, so that I can access the correct dashboard without navigating multiple screens.

#### Acceptance Criteria

1. THE Auth_Screen SHALL display both login and register forms within a single scrollable view, toggled by a tab control.
2. THE Auth_Screen SHALL render a Role_Toggle with exactly two options: "Teacher" and "Student", styled in Cobalt_Blue.
3. WHEN a User submits the login form, THE Auth_Service SHALL authenticate the User against Firebase using email and password credentials.
4. WHEN a User taps the Google Sign-In button, THE Auth_Service SHALL initiate Firebase Google OAuth authentication and retrieve the User's profile.
5. WHEN authentication succeeds and the selected role is "Student", THE App SHALL navigate the User to the Student_Dashboard.
6. WHEN authentication succeeds and the selected role is "Teacher", THE App SHALL navigate the User to the Teacher_Dashboard.
7. IF authentication fails, THEN THE Auth_Screen SHALL display a descriptive inline error message below the relevant form field within 300ms of the failure response.
8. WHEN a User submits the register form, THE Auth_Service SHALL create a new Firebase account and persist the selected role to the Laravel_API user profile endpoint.
9. THE Auth_Screen SHALL apply Design_System Glass_Card styling to the form container.

---

### Requirement 3: Student Dashboard — Joined Classes

**User Story:** As a Student, I want to see all my joined classes in one place, so that I can quickly access course materials and track my progress.

#### Acceptance Criteria

1. WHEN the Student_Dashboard loads, THE Class_Service SHALL fetch the authenticated Student's joined classes from the Laravel_API `/classes` endpoint.
2. THE Student_Dashboard SHALL render each joined class as a Glass_Card displaying the class name, subject, and teacher name.
3. WHILE the Class_Service is fetching data, THE Student_Dashboard SHALL display a loading skeleton in place of each class card.
4. IF the Laravel_API returns an error, THEN THE Student_Dashboard SHALL display a retry button and an error message describing the failure.
5. THE Student_Dashboard SHALL display an assignment progress tracker per class, showing completed assignments out of total assignments as a percentage.

---

### Requirement 4: Student Dashboard — Exam Countdown

**User Story:** As a Student, I want to see a real-time countdown to my next exam, so that I can prepare accordingly.

#### Acceptance Criteria

1. WHEN the Student_Dashboard loads, THE Exam_Service SHALL subscribe to the active exam schedule from Firebase Realtime Database.
2. WHILE an upcoming exam is scheduled, THE Student_Dashboard SHALL display a countdown timer showing days, hours, minutes, and seconds remaining.
3. WHEN the countdown reaches zero, THE Student_Dashboard SHALL replace the countdown with an "Enter Exam" button that navigates to the Exam_Interface.
4. WHILE the Firebase subscription is active, THE Exam_Service SHALL update the countdown display every 1 second without requiring a page refresh.
5. IF no upcoming exam is scheduled, THEN THE Student_Dashboard SHALL display a "No upcoming exams" placeholder within the countdown section.

---

### Requirement 5: Teacher Dashboard — Master Exam Toggle

**User Story:** As a Teacher, I want to control exam availability with a single toggle, so that I can open or close exams for all students simultaneously.

#### Acceptance Criteria

1. THE Teacher_Dashboard SHALL display a "Master Exam Toggle" switch styled in Cobalt_Blue.
2. WHEN a Teacher activates the Master Exam Toggle, THE Exam_Service SHALL write an `exam_active: true` flag to the Firebase Realtime Database exam node.
3. WHEN a Teacher deactivates the Master Exam Toggle, THE Exam_Service SHALL write an `exam_active: false` flag to the Firebase Realtime Database exam node.
4. WHEN the Master Exam Toggle state changes, THE Audit_Log_Service SHALL record an audit entry containing the Teacher's user ID, the action performed, and a UTC timestamp.
5. THE Teacher_Dashboard SHALL reflect the current Master Exam Toggle state from Firebase within 500ms of any remote state change.

---

### Requirement 6: Teacher Dashboard — Student List Management

**User Story:** As a Teacher, I want to manage students in my class, so that I can verify legitimate enrollments and remove unauthorized participants.

#### Acceptance Criteria

1. WHEN the Teacher_Dashboard loads, THE Class_Service SHALL fetch the student roster for the Teacher's class from the Laravel_API `/classes/{id}/students` endpoint.
2. THE Teacher_Dashboard SHALL render each student as a list item displaying the student's name, email, and verification status.
3. WHEN a Teacher taps "Verify" on a student, THE Class_Service SHALL send a PATCH request to the Laravel_API `/students/{id}/verify` endpoint and update the student's verification status in the list.
4. WHEN a Teacher taps "Remove" on a student, THE Class_Service SHALL send a DELETE request to the Laravel_API `/classes/{id}/students/{id}` endpoint and remove the student from the rendered list.
5. IF the Laravel_API returns an error on a Verify or Remove action, THEN THE Teacher_Dashboard SHALL display a toast notification describing the error within 300ms.

---

### Requirement 7: Teacher Dashboard — Real-Time Audit Logs

**User Story:** As a Teacher, I want to see a live feed of classroom activity, so that I can monitor student behavior and exam integrity in real time.

#### Acceptance Criteria

1. WHEN the Teacher_Dashboard loads, THE Audit_Log_Service SHALL subscribe to the audit log stream from Firebase Realtime Database.
2. WHILE the Firebase subscription is active, THE Teacher_Dashboard SHALL append new audit log entries to the log list in real time without requiring a page refresh.
3. THE Teacher_Dashboard SHALL render each audit log entry displaying the actor's name, the action description, and the UTC timestamp.
4. THE Teacher_Dashboard SHALL display the 50 most recent audit log entries, with older entries scrollable below.
5. IF the Firebase subscription is interrupted, THEN THE Audit_Log_Service SHALL attempt to reconnect and THE Teacher_Dashboard SHALL display a "Reconnecting..." status indicator.

---

### Requirement 8: Advanced Exam Interface

**User Story:** As a Student, I want to take a proctored exam with essay inputs and cloud sync, so that my answers are securely submitted and my session is monitored for integrity.

#### Acceptance Criteria

1. WHEN a Student enters the Exam_Interface, THE Exam_Service SHALL load the exam questions from Firebase Realtime Database for the active exam session.
2. THE Exam_Interface SHALL render each essay question with a multi-line text input field supporting a minimum of 2000 characters.
3. WHILE the Student is in the Exam_Interface, THE Anti_Cheat_Monitor SHALL detect app-switching events and tab-out events.
4. WHEN the Anti_Cheat_Monitor detects a violation, THE Exam_Interface SHALL display a violation warning overlay and THE Audit_Log_Service SHALL record the violation with the Student's user ID and a UTC timestamp.
5. THE Exam_Interface SHALL display a "Sync to Cloud" status indicator showing one of three states: "Synced", "Syncing...", or "Sync Failed".
6. WHILE the Student is typing an answer, THE Exam_Service SHALL auto-save the answer draft to Firebase every 30 seconds.
7. WHEN a Student taps "Submit Exam", THE Exam_Service SHALL write the final answers to Firebase and send a submission confirmation to the Laravel_API `/exams/{id}/submit` endpoint.
8. IF the submission to Laravel_API fails, THEN THE Exam_Service SHALL retain the answers in Firebase and THE Exam_Interface SHALL display a "Sync Failed" status with a manual retry button.
9. WHEN the exam time limit expires, THE Exam_Interface SHALL automatically trigger the submission flow defined in criterion 7.

---

### Requirement 9: Session Management & Security

**User Story:** As a User, I want my session to be securely managed, so that my data is protected and I am not unexpectedly logged out.

#### Acceptance Criteria

1. WHEN a User's Firebase auth token expires, THE Auth_Service SHALL silently refresh the token without interrupting the User's session.
2. WHEN a User taps "Sign Out", THE Auth_Service SHALL revoke the Firebase session, clear all local cached credentials, and navigate the User to the Auth_Screen.
3. IF the App is launched and a valid Firebase session exists, THEN THE Auth_Service SHALL restore the session and navigate the User to the appropriate dashboard based on the stored role.
4. THE Auth_Service SHALL store the User's role selection in secure local storage, not in plain-text shared preferences.
