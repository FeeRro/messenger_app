CREATE SCHEMA whatsapp;

CREATE TABLE whatsapp.user (
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    version      BIGINT NOT NULL DEFAULT 1,
    phone_number VARCHAR(15) NOT NULL UNIQUE CHECK (
        phone_number ~ '^\+?[0-9]+$'
        AND char_length(phone_number) BETWEEN 10 AND 15
    ),
    name         VARCHAR(100) NOT NULL CHECK (char_length(name) BETWEEN 3 AND 100),
    created_at   TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE whatsapp.chat (
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    type       VARCHAR(10) NOT NULL CHECK (type IN ('direct', 'group')),
    created_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE whatsapp.chat_member (
    chat_id   BIGINT NOT NULL REFERENCES whatsapp.chat(id) ON DELETE CASCADE,
    user_id   BIGINT NOT NULL REFERENCES whatsapp.user(id) ON DELETE CASCADE,
    joined_at TIMESTAMP NOT NULL DEFAULT now(),
    PRIMARY KEY (chat_id, user_id)
);

CREATE TABLE whatsapp.message (
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    version    BIGINT NOT NULL DEFAULT 1,
    chat_id    BIGINT NOT NULL REFERENCES whatsapp.chat(id) ON DELETE CASCADE,
    sender_id  BIGINT NOT NULL REFERENCES whatsapp.user(id) ON DELETE CASCADE,
    content    TEXT CHECK (content IS NULL OR char_length(content) BETWEEN 1 AND 2000),
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE whatsapp.attachment (
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    message_id   BIGINT NOT NULL REFERENCES whatsapp.message(id) ON DELETE CASCADE,
    storage_key  TEXT NOT NULL,            
    file_name    VARCHAR(255) NOT NULL,    
    content_type VARCHAR(100) NOT NULL,    
    size_bytes   BIGINT NOT NULL CHECK (size_bytes > 0),
    created_at   TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX idx_chat_member_user     ON whatsapp.chat_member (user_id);
CREATE INDEX idx_message_chat_created ON whatsapp.message (chat_id, created_at);
CREATE INDEX idx_attachment_message   ON whatsapp.attachment (message_id);

CREATE FUNCTION whatsapp.check_message_not_empty()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.content IS NULL
       AND NOT EXISTS (
           SELECT 1 FROM whatsapp.attachment WHERE message_id = NEW.id
       )
    THEN
        RAISE EXCEPTION 'message % has neither text nor attachment', NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER message_not_empty
    AFTER INSERT OR UPDATE ON whatsapp.message
    DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW
    EXECUTE FUNCTION whatsapp.check_message_not_empty();
