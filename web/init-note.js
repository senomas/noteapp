import {createClient} from '@supabase/supabase-js';
import * as fs from 'fs';
import {exit} from 'process';

const env = fs
  .readFileSync('.env')
  .toString()
  .split('\n')
  .map(v => v.trim().split('='))
  .reduce((acc, [k, v]) => {
    if (k) {
      acc[k] = v;
    }
    return acc;
  }, {});

const supabase = createClient(
  env.VITE_SUPABASE_URL,
  env.VITE_SUPABASE_ANON_KEY
);

async function login({email, password}) {
  const {error} = await supabase.auth.signIn({
    email,
    password
  });
  if (error) {
    if (error.status === 400 && error.message === 'User already registered') {
      console.log({email, ...error});
      return;
    }
    throw error;
  }
}

async function saveNote(title, content) {
  const {data, error} = await supabase
    .from('notes')
    .upsert({title, content}, {onConflict: 'owner_id, title'});
  if (error) {
    throw {saveNote: {error, req: {title, content}, data}};
  }
  console.log(JSON.stringify({upsert: {data}}, undefined, 2));
  return data[0].id;
}

async function selectNotes(users) {
  const {data, error} = await supabase.from('notes').select('*');
  if (error) {
    throw error;
  }
  return data.map(v => ({
    ...v,
    created_by: (users.filter(u => u.id === v.created_by)[0] || {}).email,
    updated_by: (users.filter(u => u.id === v.updated_by)[0] || {}).email,
    owner_id: (users.filter(u => u.id === v.owner_id)[0] || {}).email
  }));
}

(async () => {
  await login({
    email: 'admin@noteapp.com',
    password: 'dodol123'
  });
  let {data, error} = await supabase.from('user_views').select('*');
  if (error) {
    throw error;
  }
  const users = data;

  await saveNote('note 1', [{t: 0, c: 'line 1'}]);
  await saveNote('note 1', [
    {t: 0, c: 'line 1'},
    {t: 0, c: 'line 2'},
    {t: 1, c: 'line 2.1'},
    {t: 1, c: 'line 2.2'}
  ]);
  console.log(
    '\n\n\nADMIN >>>>>>> ' +
      JSON.stringify(await selectNotes(users), undefined, 2)
  );

  await login({
    email: 'admin2@noteapp.com',
    password: 'dodol123'
  });
  await saveNote('note 1', [
    {t: 0, c: 'line 1'},
    {t: 0, c: 'line 2'},
    {t: 1, c: 'line 2.1'},
    {t: 1, c: 'line 2.2'}
  ]);
  await saveNote('note 2', [
    {t: 0, c: 'note 2 line 1'},
    {t: 0, c: 'note 2 line 2'},
    {t: 1, c: 'note 2 line 2.1'},
    {t: 1, c: 'note 2 line 2.2'}
  ]);
  console.log(
    '\n\n\nADMIN2 >>>>>>> ' +
      JSON.stringify(await selectNotes(users), undefined, 2)
  );

  await login({
    email: 'admin@noteapp.com',
    password: 'dodol123'
  });
  console.log(
    '\n\n\nADMIN >>>>>>> ' +
      JSON.stringify(await selectNotes(users), undefined, 2)
  );

  await login({
    email: 'super_admin@noteapp.com',
    password: 'dodol123'
  });
  console.log(
    '\n\n\nSUPER_ADMIN >>>>>>> ' +
      JSON.stringify(await selectNotes(users), undefined, 2)
  );
})()
  .then(() => console.log('DONE init-note'))
  .catch(err => {
    console.log(err);
    exit(-1);
  });
