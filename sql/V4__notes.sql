DROP TABLE IF EXISTS note_archives CASCADE;
DROP TABLE IF EXISTS notes CASCADE;
DROP FUNCTION IF EXISTS trigger_on_notes;

CREATE TABLE notes (
  id SERIAL NOT NULL PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  created_by UUID REFERENCES auth.users,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_by UUID REFERENCES auth.users,
  owner_id UUID REFERENCES auth.users NOT NULL,
  title TEXT NOT NULL,
  content JSONB NOT NULL,
  CONSTRAINT notes__title UNIQUE (owner_id, title),
  CONSTRAINT notes_validate CHECK (char_length(title) >= 3)
);


ALTER TABLE notes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "select notes with permissions notes.select" ON notes FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM user_permission_views u 
      WHERE (u.role = 'super_admin' OR (owner_id = auth.uid() AND u.permission = 'notes.select')) AND auth.uid() = u.id
    )
  );
CREATE POLICY "update notes with permissions notes.update" ON notes FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM user_permission_views u 
      WHERE (u.role = 'super_admin' OR (owner_id = auth.uid() AND u.permission = 'notes.update')) AND auth.uid() = u.id
    )
  ) WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_permission_views u 
      WHERE (u.role = 'super_admin' OR (owner_id = auth.uid() AND u.permission = 'notes.update')) AND auth.uid() = u.id
    )
  );
CREATE POLICY "insert notes with permissions notes.insert" ON notes FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_permission_views u 
      WHERE (u.role = 'super_admin' OR u.permission = 'notes.insert') AND auth.uid() = u.id
    )
  );
CREATE POLICY "delete notes with permissions notes.delete" ON notes FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM user_permission_views u 
      WHERE (u.role = 'super_admin' OR (owner_id = auth.uid() AND u.permission = 'notes.delete')) AND auth.uid() = u.id
    )
  );


CREATE TABLE note_archives (
  id SERIAL NOT NULL PRIMARY KEY,
  op TEXT NOT NULL,
  performed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  performed_by UUID,
  note_id INT,
  owner_id UUID,
  created_at TIMESTAMP WITH TIME ZONE,
  created_by UUID,
  updated_at TIMESTAMP WITH TIME ZONE,
  updated_by UUID,
  title TEXT,
  content JSONB
);

ALTER TABLE note_archives ENABLE ROW LEVEL SECURITY;
CREATE POLICY "select note_archives with permissions notes.select" ON note_archives FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM user_permission_views u 
      WHERE (u.role = 'super_admin' OR (owner_id = auth.uid() AND u.permission = 'notes.select')) AND auth.uid() = u.id
    )
  );
CREATE POLICY "insert note_archives with permissions notes.insert" ON note_archives FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_permission_views u 
      WHERE (u.role = 'super_admin' OR u.permission = 'notes.insert') AND auth.uid() = u.id
    )
  );


CREATE FUNCTION trigger_on_notes() RETURNS TRIGGER AS $BODY$
BEGIN
  new.updated_at = NOW();
  new.updated_by = auth.uid();
  IF TG_OP = 'DELETE' THEN
    INSERT INTO note_archives(op, performed_by, note_id, owner_id, created_at, created_by, updated_at, updated_by, title, content)
      VALUES (TG_WHEN || ' ' || TG_OP, auth.uid(), old.id, old.owner_id, old.created_at, old.created_by, old.updated_at, old.updated_by, old.title, old.content);
    RETURN old;
  ELSEIF TG_OP = 'UPDATE' THEN
    INSERT INTO note_archives(op, performed_by, note_id, owner_id, created_at, created_by, updated_at, updated_by, title, content)
      VALUES (TG_WHEN || ' ' || TG_OP, auth.uid(), old.id, old.owner_id, old.created_at, old.created_by, old.updated_at, old.updated_by, old.title, old.content);
    RETURN new;
  ELSEIF TG_OP = 'INSERT' THEN
    new.created_by = auth.uid();
    new.owner_id = auth.uid();
    INSERT INTO note_archives(op, performed_by, note_id, owner_id)
      VALUES (TG_WHEN || ' ' || TG_OP, auth.uid(), new.id, new.owner_id);
    RETURN new;
  ELSE
    INSERT INTO note_archives(op, performed_by, note_id, owner_id)
      VALUES (TG_WHEN || ' ' || TG_OP, auth.uid(), new.id, new.owner_id);
    RETURN new;
  END IF;
END;
$BODY$
language plpgsql;

CREATE TRIGGER notes_before_trigger
BEFORE INSERT OR UPDATE OR DELETE ON notes
FOR EACH ROW
EXECUTE PROCEDURE trigger_on_notes();
