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
CREATE POLICY "allow update app_roles to users based on email" ON app_roles FOR UPDATE USING (auth.email() = 'super_admin@noteapp.com') WITH CHECK (auth.email() = 'super_admin@noteapp.com');
CREATE POLICY "allow insert app_roles to users based on email" ON app_roles FOR INSERT WITH CHECK (auth.email() = 'super_admin@noteapp.com');
CREATE POLICY "allow delete app_roles to users based on email" ON app_roles FOR DELETE USING (auth.email() = 'super_admin@noteapp.com');

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
CREATE POLICY "allow update app_permissions to users based on email" ON app_permissions FOR UPDATE USING (auth.email() = 'super_admin@noteapp.com') WITH CHECK (auth.email() = 'super_admin@noteapp.com');
CREATE POLICY "allow insert app_permissions to users based on email" ON app_permissions FOR INSERT WITH CHECK (auth.email() = 'super_admin@noteapp.com');
CREATE POLICY "allow delete app_permissions to users based on email" ON app_permissions FOR DELETE USING (auth.email() = 'super_admin@noteapp.com');


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
CREATE POLICY "allow update user_app_roles to users based on email" ON user_app_roles FOR UPDATE USING (auth.email() = 'super_admin@noteapp.com') WITH CHECK (auth.email() = 'super_admin@noteapp.com');
CREATE POLICY "allow insert user_app_roles to users based on email" ON user_app_roles FOR INSERT WITH CHECK (auth.email() = 'super_admin@noteapp.com');
CREATE POLICY "allow delete user_app_roles to users based on email" ON user_app_roles FOR DELETE USING (auth.email() = 'super_admin@noteapp.com');


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
CREATE POLICY "allow update app_role_permissions to users based on email" ON app_role_permissions FOR UPDATE USING (auth.email() = 'super_admin@noteapp.com') WITH CHECK (auth.email() = 'super_admin@noteapp.com');
CREATE POLICY "allow insert app_role_permissions to users based on email" ON app_role_permissions FOR INSERT WITH CHECK (auth.email() = 'super_admin@noteapp.com');
CREATE POLICY "allow delete app_role_permissions to users based on email" ON app_role_permissions FOR DELETE USING (auth.email() = 'super_admin@noteapp.com');



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



CREATE VIEW user_permission_views AS 
SELECT u.id, u.email email, r.name as role, p.name as permission FROM auth.users u INNER JOIN user_app_roles ur ON u.id = ur.user_id
      INNER JOIN app_roles r ON ur.app_role_id = r.id
      LEFT JOIN app_role_permissions rp ON ur.app_role_id = rp.app_role_id
      LEFT JOIN app_permissions p ON rp.app_permission_id = p.id;
