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

async function createNote(title, content) {
  const {data, error} = await supabase.from('notes').insert({title, content});
  if (error) {
    throw error;
  }
  console.log({data});
  return data[0].id;
}

async function updateNote(id, title, content) {
  const {data, error} = await supabase
    .from('notes')
    .update({title, content})
    .eq('id', id);
  if (error) {
    throw error;
  }
  console.log({data});
  return data;
}

(async () => {
  await login({
    email: 'admin@noteapp.com',
    password: 'dodol123'
  });
  const nid = await createNote('note 1', 'this is very long note 1');
  await updateNote(nid, 'note 1 update', 'this is very long note 1 update');

  await login({
    email: 'admin2@noteapp.com',
    password: 'dodol123'
  });
  const nid2 = await createNote('note 2', 'this is very long note 2');
  await updateNote(nid2, 'note 2 update', 'this is very long note 2 update');

  await updateNote(nid, 'note 1 failed', 'this is very long note 1 failed');
})()
  .then(() => console.log('DONE init-note'))
  .catch(err => {
    console.log(err);
    exit(-1);
  });
