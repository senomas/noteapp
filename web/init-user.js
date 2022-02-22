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

async function createUser({email, password}) {
  const {error} = await supabase.auth.signUp({
    email,
    password
  });
  if (error) {
    if (error.status === 400 && error.message === 'User already registered') {
      // console.log({email, ...error});
      return;
    }
    throw error;
  }
  // console.log({user});
}

(async () => {
  await createUser({
    email: 'super_admin@noteapp.com',
    password: 'dodol123'
  });
  await createUser({
    email: 'admin@noteapp.com',
    password: 'dodol123'
  });
  await createUser({
    email: 'admin2@noteapp.com',
    password: 'dodol123'
  });
  await createUser({
    email: 'opr@noteapp.com',
    password: 'dodol123'
  });
  await createUser({
    email: 'user1@noteapp.com',
    password: 'dodol123'
  });
  await createUser({
    email: 'user2@noteapp.com',
    password: 'dodol123'
  });

  let {data, error} = await supabase.from('user_views').select('*');
  if (error) {
    throw error;
  }
  const users = data;

  ({data, error} = await supabase
    .from('app_role_permissions')
    .select(
      '*, role:app_role_id (id), permission:app_permission_id!left ( id, name )'
    ));
  if (error) {
    throw error;
  }
  const role_permissions = data.map(v => ({
    ...v.role,
    permission: v.permission
  }));

  ({data, error} = await supabase.from('app_roles').select('*'));
  if (error) {
    throw error;
  }
  const roles = data.map(v => ({
    id: v.id,
    name: v.name,
    permission: (role_permissions.filter(rp => rp.id === v.id)[0] || {})
      .permission
  }));
  // console.log(JSON.stringify({roles}, undefined, 2));

  ({data, error} = await supabase.from('user_app_roles').select('*'));
  if (error) {
    throw error;
  }
  const res = data.map(v => ({
    id: v.user_id,
    email: users.filter(u => u.id === v.user_id)[0].email,
    role: roles.filter(u => u.id === v.app_role_id)[0]
  }));
  console.log(JSON.stringify({res}, undefined, 2));
})()
  .then(() => console.log('DONE init-user'))
  .catch(err => {
    console.log(err);
    exit(-1);
  });
