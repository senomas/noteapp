INSERT INTO app_roles (name) VALUES ('super_admin');
INSERT INTO app_roles (name) VALUES ('admin');
INSERT INTO app_roles (name) VALUES ('operator');
INSERT INTO app_roles (name) VALUES ('user');

-- INSERT INTO app_permissions (name) VALUES ('super_admin');
INSERT INTO app_permissions (name) VALUES ('notes.select');
INSERT INTO app_permissions (name) VALUES ('notes.update');
INSERT INTO app_permissions (name) VALUES ('notes.insert');
INSERT INTO app_permissions (name) VALUES ('notes.delete');

-- INSERT INTO app_role_permissions(app_role_id, app_permission_id) SELECT r.id as uid, p.id as pid FROM app_roles r, app_permissions p WHERE r.name = 'super_admin' AND p.name = 'super_admin';

INSERT INTO app_role_permissions(app_role_id, app_permission_id) SELECT r.id as uid, p.id as pid FROM app_roles r, app_permissions p WHERE r.name = 'admin';
INSERT INTO app_role_permissions(app_role_id, app_permission_id) SELECT r.id as uid, p.id as pid FROM app_roles r, app_permissions p WHERE r.name = 'operator' AND NOT(p.name LIKE '%.delete');
INSERT INTO app_role_permissions(app_role_id, app_permission_id) SELECT r.id as uid, p.id as pid FROM app_roles r, app_permissions p WHERE r.name = 'user' AND p.name LIKE '%.select';
 
INSERT INTO user_app_roles(user_id, app_role_id) SELECT u.id as uid, r.id as rid FROM auth.users u, app_roles r WHERE u.email = 'super_admin@noteapp.com' AND (r.name = 'super_admin');
INSERT INTO user_app_roles(user_id, app_role_id) SELECT u.id as uid, r.id as rid FROM auth.users u, app_roles r WHERE u.email = 'admin@noteapp.com' AND (r.name = 'admin');
INSERT INTO user_app_roles(user_id, app_role_id) SELECT u.id as uid, r.id as rid FROM auth.users u, app_roles r WHERE u.email = 'admin2@noteapp.com' AND r.name = 'admin';
INSERT INTO user_app_roles(user_id, app_role_id) SELECT u.id as uid, r.id as rid FROM auth.users u, app_roles r WHERE u.email = 'opr@noteapp.com' AND r.name = 'operator';
INSERT INTO user_app_roles(user_id, app_role_id) SELECT u.id as uid, r.id as rid FROM auth.users u, app_roles r WHERE u.email = 'user1@noteapp.com' AND r.name = 'user';
INSERT INTO user_app_roles(user_id, app_role_id) SELECT u.id as uid, r.id as rid FROM auth.users u, app_roles r WHERE u.email = 'user2@noteapp.com' AND r.name = 'user';
