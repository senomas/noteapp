DROP TABLE IF EXISTS app_roles CASCADE;
DROP TABLE IF EXISTS app_role_permissions CASCADE;
DROP TABLE IF EXISTS app_permissions CASCADE;
DROP TABLE IF EXISTS user_app_roles CASCADE;
DROP VIEW  IF EXISTS user_views CASCADE;
DROP FUNCTION  IF EXISTS fn_user_views CASCADE;


CREATE TABLE app_roles (
  id SERIAL NOT NULL PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  created_by UUID REFERENCES auth.users,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_by UUID REFERENCES auth.users,
  name TEXT NOT NULL,
  description TEXT
);

ALTER TABLE app_roles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "allow select app_roles to all users" ON app_roles FOR SELECT USING (true);
CREATE POLICY "allow update app_roles to users based on email" ON app_roles FOR UPDATE USING (auth.email() LIKE 'admin@noteapp.com') WITH CHECK (auth.email() LIKE 'admin@noteapp.com');
CREATE POLICY "allow insert app_roles to users based on email" ON app_roles FOR INSERT WITH CHECK (auth.email() LIKE 'admin@noteapp.com');
CREATE POLICY "allow delete app_roles to users based on email" ON app_roles FOR DELETE USING (auth.email() LIKE 'admin@noteapp.com');

CREATE TABLE app_permissions (
  id SERIAL NOT NULL PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  created_by UUID REFERENCES auth.users,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_by UUID REFERENCES auth.users,
  name TEXT NOT NULL,
  description TEXT
);

ALTER TABLE app_permissions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "allow select app_permissions to all users" ON app_permissions FOR SELECT USING (true);
CREATE POLICY "allow update app_permissions to users based on email" ON app_permissions FOR UPDATE USING (auth.email() LIKE 'admin@noteapp.com') WITH CHECK (auth.email() LIKE 'admin@noteapp.com');
CREATE POLICY "allow insert app_permissions to users based on email" ON app_permissions FOR INSERT WITH CHECK (auth.email() LIKE 'admin@noteapp.com');
CREATE POLICY "allow delete app_permissions to users based on email" ON app_permissions FOR DELETE USING (auth.email() LIKE 'admin@noteapp.com');


CREATE TABLE user_app_roles (
  id SERIAL NOT NULL PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  created_by UUID REFERENCES auth.users,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_by UUID REFERENCES auth.users,
  user_id UUID REFERENCES auth.users,
  app_role_id INT REFERENCES app_roles,
  CONSTRAINT user_app_roles_link UNIQUE(user_id, app_role_id)
);

ALTER TABLE user_app_roles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "allow select user_app_roles to all users" ON user_app_roles FOR SELECT USING (true);
CREATE POLICY "allow update user_app_roles to users based on email" ON user_app_roles FOR UPDATE USING (auth.email() LIKE 'admin@noteapp.com') WITH CHECK (auth.email() LIKE 'admin@noteapp.com');
CREATE POLICY "allow insert user_app_roles to users based on email" ON user_app_roles FOR INSERT WITH CHECK (auth.email() LIKE 'admin@noteapp.com');
CREATE POLICY "allow delete user_app_roles to users based on email" ON user_app_roles FOR DELETE USING (auth.email() LIKE 'admin@noteapp.com');


CREATE TABLE app_role_permissions (
  id SERIAL NOT NULL PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  created_by UUID REFERENCES auth.users,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_by UUID REFERENCES auth.users,
  app_role_id INT REFERENCES app_roles,
  app_permission_id INT REFERENCES app_permissions,
  CONSTRAINT app_role_permissions_link UNIQUE(app_role_id, app_permission_id)
);

ALTER TABLE app_role_permissions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "allow select app_role_permissions to all users" ON app_role_permissions FOR SELECT USING (true);
CREATE POLICY "allow update app_role_permissions to users based on email" ON app_role_permissions FOR UPDATE USING (auth.email() LIKE 'admin@noteapp.com') WITH CHECK (auth.email() LIKE 'admin@noteapp.com');
CREATE POLICY "allow insert app_role_permissions to users based on email" ON app_role_permissions FOR INSERT WITH CHECK (auth.email() LIKE 'admin@noteapp.com');
CREATE POLICY "allow delete app_role_permissions to users based on email" ON app_role_permissions FOR DELETE USING (auth.email() LIKE 'admin@noteapp.com');



CREATE FUNCTION fn_user_views()
RETURNS TABLE (
  instance_id UUID,
  id UUID,
  email VARCHAR,
  roles TEXT,
  created_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT 
    u.instance_id,
    u.id,
    u.email,
    ur.roles,
    u.created_at,
    u.updated_at
  FROM
    auth.users u LEFT JOIN (
      SELECT u.user_id, string_agg(r.name, ' || ') AS roles FROM user_app_roles u, app_roles r WHERE u.app_role_id = r.id GROUP BY u.user_id
    ) ur ON u.id = ur.user_id;
$$;

CREATE VIEW user_views AS SELECT * FROM fn_user_views();



INSERT INTO app_roles (name) VALUES ('admin');
INSERT INTO app_roles (name) VALUES ('operator');
INSERT INTO app_roles (name) VALUES ('user');

INSERT INTO app_permissions (name) VALUES ('notes.select');
INSERT INTO app_permissions (name) VALUES ('notes.update');
INSERT INTO app_permissions (name) VALUES ('notes.insert');
INSERT INTO app_permissions (name) VALUES ('notes.delete');

INSERT INTO app_role_permissions(app_role_id, app_permission_id) SELECT r.id as uid, p.id as pid FROM app_roles r, app_permissions p WHERE r.name = 'admin';
INSERT INTO app_role_permissions(app_role_id, app_permission_id) SELECT r.id as uid, p.id as pid FROM app_roles r, app_permissions p WHERE r.name = 'operator' AND NOT(p.name LIKE '%.delete');
INSERT INTO app_role_permissions(app_role_id, app_permission_id) SELECT r.id as uid, p.id as pid FROM app_roles r, app_permissions p WHERE r.name = 'user' AND p.name LIKE '%.select';
 
INSERT INTO user_app_roles(user_id, app_role_id) SELECT u.id as uid, r.id as rid FROM auth.users u, app_roles r WHERE u.email = 'admin@noteapp.com' AND r.name = 'admin';
INSERT INTO user_app_roles(user_id, app_role_id) SELECT u.id as uid, r.id as rid FROM auth.users u, app_roles r WHERE u.email = 'admin2@noteapp.com' AND r.name = 'admin';
INSERT INTO user_app_roles(user_id, app_role_id) SELECT u.id as uid, r.id as rid FROM auth.users u, app_roles r WHERE u.email = 'opr@noteapp.com' AND r.name = 'operator';
INSERT INTO user_app_roles(user_id, app_role_id) SELECT u.id as uid, r.id as rid FROM auth.users u, app_roles r WHERE u.email = 'user1@noteapp.com' AND r.name = 'user';
INSERT INTO user_app_roles(user_id, app_role_id) SELECT u.id as uid, r.id as rid FROM auth.users u, app_roles r WHERE u.email = 'user2@noteapp.com' AND r.name = 'user';
