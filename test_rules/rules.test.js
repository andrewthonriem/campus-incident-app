// Security-rules tests for Firestore, run against the Firebase Emulator.
//
//   cd test_rules
//   npm install
//   npx firebase emulators:exec --only firestore --project demo-campus "npm test"
//
const fs = require('fs');
const path = require('path');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const {
  doc,
  setDoc,
  updateDoc,
  getDoc,
  deleteDoc,
  Timestamp,
} = require('firebase/firestore');
let env;

const validIncident = (uid) => ({
  title: 'Water shortage',
  description: 'No water on the 2nd floor since this morning.',
  category: 'water',
  location: 'Student Residence',
  status: 'submitted',
  reporterId: uid,
  reporterName: 'Amina',
  imageUrl: null,
  imagePath: null,
  createdAt: Timestamp.now(),
  updatedAt: Timestamp.now(),
  history: [{ status: 'submitted', changedBy: uid, changedByName: 'Amina', note: '', at: Timestamp.now() }],
});

const campusDb = (uid, claims = {}) => env.authenticatedContext(uid, {
  email: 'student@alustudent.com',
  email_verified: true,
  ...claims,
}).firestore();

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-campus',
    firestore: { rules: fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8') },
  });
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users/staff1'), { name: 'Staff', email: 's@x.com', role: 'staff', department: '' });
    await setDoc(doc(db, 'users/student1'), { name: 'Amina', email: 'a@x.com', role: 'student', department: '' });
    await setDoc(doc(db, 'incidents/i1'), validIncident('student1'));
  });
});

after(async () => env.cleanup());

describe('users', () => {
  it('a new user can create their own student profile', async () => {
    const db = campusDb('newbie', {
      email: 'new.student@ALUSTUDENT.COM',
      email_verified: false,
    });
    await assertSucceeds(setDoc(doc(db, 'users/newbie'), {
      name: 'N',
      email: 'new.student@ALUSTUDENT.COM',
      role: 'student',
      department: '',
    }));
  });

  it('matches profile email to the auth email without case sensitivity', async () => {
    const db = campusDb('case-check', {
      email: 'New.Student@ALUSTUDENT.COM',
      email_verified: false,
    });
    await assertSucceeds(setDoc(doc(db, 'users/case-check'), {
      name: 'New Student',
      email: 'new.student@alustudent.com',
      role: 'student',
      department: '',
    }));
  });

  it('an unverified @aluedu.com account can create a staff profile', async () => {
    const db = campusDb('new-staff', {
      email: 'new.staff@aluedu.com',
      email_verified: false,
    });
    await assertSucceeds(setDoc(doc(db, 'users/new-staff'), {
      name: 'New Staff',
      email: 'new.staff@aluedu.com',
      role: 'staff',
      department: '',
    }));
  });

  it('an @aluedu.com account cannot create a student profile', async () => {
    const db = campusDb('wrong-role', {
      email: 'new.staff@aluedu.com',
      email_verified: false,
    });
    await assertFails(setDoc(doc(db, 'users/wrong-role'), {
      name: 'New Staff',
      email: 'new.staff@aluedu.com',
      role: 'student',
      department: '',
    }));
  });

  it('a non-ALU account cannot create a profile', async () => {
    const db = campusDb('outsider', { email: 'student@example.com' });
    await assertFails(setDoc(doc(db, 'users/outsider'), {
      name: 'O',
      email: 'student@example.com',
      role: 'student',
      department: '',
    }));
  });

  it('a user cannot register themselves as staff', async () => {
    const db = campusDb('sneaky');
    await assertFails(setDoc(doc(db, 'users/sneaky'), { name: 'S', email: 's@x.com', role: 'staff', department: '' }));
  });

  it('a student cannot promote themselves to staff', async () => {
    const db = campusDb('student1');
    await assertFails(updateDoc(doc(db, 'users/student1'), { role: 'staff' }));
  });
});

describe('incidents', () => {
  it('unauthenticated users cannot read reports', async () => {
    const db = env.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, 'incidents/i1')));
  });

  it('a student can submit a valid report', async () => {
    const db = campusDb('student1');
    await assertSucceeds(setDoc(doc(db, 'incidents/new'), validIncident('student1')));
  });

  it('a student cannot submit a report on behalf of someone else', async () => {
    const db = campusDb('student1');
    await assertFails(setDoc(doc(db, 'incidents/new'), validIncident('someoneElse')));
  });

  it('a student cannot create a report that is already resolved', async () => {
    const db = campusDb('student1');
    await assertFails(setDoc(doc(db, 'incidents/new'), { ...validIncident('student1'), status: 'resolved' }));
  });

  it('a student CANNOT update the status', async () => {
    const db = campusDb('student1');
    await assertFails(updateDoc(doc(db, 'incidents/i1'), { status: 'resolved' }));
  });

  it('staff CAN update the status', async () => {
    const db = campusDb('staff1', { email: 'staff@alu.edu' });
    await assertSucceeds(updateDoc(doc(db, 'incidents/i1'), { status: 'inProgress', updatedAt: Timestamp.now() }));
  });

  it('an @aluedu.com account can update status with a stale student profile', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/domain-staff'), {
        name: 'Domain Staff',
        email: 'staff@aluedu.com',
        role: 'student',
        department: '',
      });
    });
    const db = campusDb('domain-staff', {
      email: 'staff@aluedu.com',
      email_verified: false,
    });
    await assertSucceeds(updateDoc(doc(db, 'incidents/i1'), {
      status: 'resolved',
      updatedAt: Timestamp.now(),
      history: [
        ...((await getDoc(doc(db, 'incidents/i1'))).data().history),
        {
          status: 'resolved',
          changedBy: 'domain-staff',
          changedByName: 'Domain Staff',
          note: '',
          at: Timestamp.now(),
        },
      ],
    }));
  });

  it('staff cannot edit the student\'s description', async () => {
    const db = campusDb('staff1', { email: 'staff@alu.edu' });
    await assertFails(updateDoc(doc(db, 'incidents/i1'), { description: 'changed by staff, which is not allowed' }));
  });

  it('the reporter can withdraw an unreviewed report', async () => {
    const db = campusDb('student1');
    await assertSucceeds(deleteDoc(doc(db, 'incidents/i1')));
  });

  it('another student cannot delete the report', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/student2'), { name: 'B', email: 'b@x.com', role: 'student', department: '' });
    });
    const db = campusDb('student2');
    await assertFails(deleteDoc(doc(db, 'incidents/i1')));
  });

  it('an unverified ALU account cannot read or create incident reports', async () => {
    const db = campusDb('student1', { email_verified: false });
    await assertFails(getDoc(doc(db, 'incidents/i1')));
    await assertFails(setDoc(doc(db, 'incidents/new'), validIncident('student1')));
  });

  it('an unverified @aluedu.com staff account can use incident reports', async () => {
    const db = campusDb('staff1', {
      email: 'staff@aluedu.com',
      email_verified: false,
    });
    await assertSucceeds(getDoc(doc(db, 'incidents/i1')));
    await assertSucceeds(setDoc(doc(db, 'incidents/new-staff-report'), validIncident('staff1')));
    await assertSucceeds(updateDoc(doc(db, 'incidents/i1'), {
      status: 'inProgress',
      updatedAt: Timestamp.now(),
    }));
  });

  it('a non-ALU account cannot read reports even when verified', async () => {
    const db = campusDb('outsider', { email: 'student@example.com' });
    await assertFails(getDoc(doc(db, 'incidents/i1')));
  });
});
