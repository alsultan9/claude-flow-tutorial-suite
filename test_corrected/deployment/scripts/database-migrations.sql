-- Database Migration Scripts for Integration System
-- Version: 1.0.0
-- Description: Initial database setup with comprehensive schema design

-- =============================================================================
-- Create Extensions and Functions
-- =============================================================================

-- UUID generation extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Case-insensitive text type
CREATE EXTENSION IF NOT EXISTS "citext";

-- Full-text search support
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- JSON operations
CREATE EXTENSION IF NOT EXISTS "btree_gin";

-- Audit timestamp function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- =============================================================================
-- User Management Schema
-- =============================================================================

-- Users table with comprehensive profile support
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email CITEXT UNIQUE NOT NULL,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(20),
    date_of_birth DATE,
    avatar_url TEXT,
    bio TEXT,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended', 'deleted')),
    email_verified BOOLEAN DEFAULT FALSE,
    phone_verified BOOLEAN DEFAULT FALSE,
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    two_factor_secret VARCHAR(32),
    preferences JSONB DEFAULT '{}',
    metadata JSONB DEFAULT '{}',
    last_login_at TIMESTAMP WITH TIME ZONE,
    last_login_ip INET,
    login_count INTEGER DEFAULT 0,
    failed_login_attempts INTEGER DEFAULT 0,
    locked_until TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- User sessions for JWT token management
CREATE TABLE IF NOT EXISTS user_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,
    refresh_token_hash VARCHAR(255) NOT NULL,
    device_info JSONB,
    ip_address INET,
    user_agent TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- User roles and permissions
CREATE TABLE IF NOT EXISTS roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    permissions JSONB DEFAULT '[]',
    is_system_role BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    granted_by UUID REFERENCES users(id),
    granted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE(user_id, role_id)
);

-- Password reset tokens
CREATE TABLE IF NOT EXISTS password_reset_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    used_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Email verification tokens
CREATE TABLE IF NOT EXISTS email_verification_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    email CITEXT NOT NULL,
    token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    verified_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- Task Management Schema
-- =============================================================================

-- Projects/Workspaces
CREATE TABLE IF NOT EXISTS projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    description TEXT,
    slug VARCHAR(100) UNIQUE NOT NULL,
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'archived', 'deleted')),
    settings JSONB DEFAULT '{}',
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Project members
CREATE TABLE IF NOT EXISTS project_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(20) DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'member', 'viewer')),
    permissions JSONB DEFAULT '[]',
    invited_by UUID REFERENCES users(id),
    invited_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    joined_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE(project_id, user_id)
);

-- Task categories/labels
CREATE TABLE IF NOT EXISTS task_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    color VARCHAR(7), -- Hex color code
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(project_id, name)
);

-- Tasks with comprehensive tracking
CREATE TABLE IF NOT EXISTS tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    title VARCHAR(500) NOT NULL,
    description TEXT,
    status VARCHAR(20) DEFAULT 'todo' CHECK (status IN ('todo', 'in_progress', 'review', 'done', 'cancelled')),
    priority VARCHAR(10) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'critical')),
    assignee_id UUID REFERENCES users(id) ON DELETE SET NULL,
    reporter_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    category_id UUID REFERENCES task_categories(id) ON DELETE SET NULL,
    parent_task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
    estimated_hours DECIMAL(8,2),
    actual_hours DECIMAL(8,2) DEFAULT 0,
    story_points INTEGER,
    due_date TIMESTAMP WITH TIME ZONE,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    tags TEXT[] DEFAULT '{}',
    custom_fields JSONB DEFAULT '{}',
    search_vector tsvector,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Task comments and activity
CREATE TABLE IF NOT EXISTS task_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    content TEXT NOT NULL,
    is_internal BOOLEAN DEFAULT FALSE,
    mentions UUID[] DEFAULT '{}',
    attachments JSONB DEFAULT '[]',
    edited_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Task activity log
CREATE TABLE IF NOT EXISTS task_activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(50) NOT NULL,
    field_name VARCHAR(50),
    old_value TEXT,
    new_value TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- File Storage Schema
-- =============================================================================

-- File uploads and attachments
CREATE TABLE IF NOT EXISTS files (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    filename VARCHAR(500) NOT NULL,
    original_filename VARCHAR(500) NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    file_size BIGINT NOT NULL,
    file_hash VARCHAR(64) NOT NULL, -- SHA-256 hash
    storage_path TEXT NOT NULL,
    storage_provider VARCHAR(20) DEFAULT 's3',
    bucket_name VARCHAR(100),
    is_public BOOLEAN DEFAULT FALSE,
    uploaded_by UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    metadata JSONB DEFAULT '{}',
    virus_scan_status VARCHAR(20) DEFAULT 'pending' CHECK (virus_scan_status IN ('pending', 'clean', 'infected', 'failed')),
    virus_scan_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- File associations (link files to various entities)
CREATE TABLE IF NOT EXISTS file_associations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    file_id UUID NOT NULL REFERENCES files(id) ON DELETE CASCADE,
    entity_type VARCHAR(50) NOT NULL, -- 'user', 'task', 'project', 'comment'
    entity_id UUID NOT NULL,
    association_type VARCHAR(20) DEFAULT 'attachment', -- 'avatar', 'attachment', 'cover'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- Notification System Schema
-- =============================================================================

-- Notification types and templates
CREATE TABLE IF NOT EXISTS notification_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    template JSONB NOT NULL,
    default_channels TEXT[] DEFAULT '{"web"}',
    is_system BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- User notification preferences
CREATE TABLE IF NOT EXISTS user_notification_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    notification_type_id UUID NOT NULL REFERENCES notification_types(id) ON DELETE CASCADE,
    channels TEXT[] DEFAULT '{"web"}',
    is_enabled BOOLEAN DEFAULT TRUE,
    frequency VARCHAR(20) DEFAULT 'immediate' CHECK (frequency IN ('immediate', 'daily', 'weekly', 'never')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, notification_type_id)
);

-- Notifications queue
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    notification_type_id UUID NOT NULL REFERENCES notification_types(id) ON DELETE RESTRICT,
    title VARCHAR(500) NOT NULL,
    content TEXT NOT NULL,
    data JSONB DEFAULT '{}',
    channels TEXT[] DEFAULT '{"web"}',
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed', 'cancelled')),
    read_at TIMESTAMP WITH TIME ZONE,
    sent_at TIMESTAMP WITH TIME ZONE,
    failed_at TIMESTAMP WITH TIME ZONE,
    retry_count INTEGER DEFAULT 0,
    scheduled_for TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- API and Integration Schema
-- =============================================================================

-- API keys for external integrations
CREATE TABLE IF NOT EXISTS api_keys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
    name VARCHAR(200) NOT NULL,
    key_hash VARCHAR(255) NOT NULL UNIQUE,
    key_prefix VARCHAR(20) NOT NULL,
    permissions JSONB DEFAULT '[]',
    rate_limit_per_hour INTEGER DEFAULT 1000,
    allowed_origins TEXT[],
    last_used_at TIMESTAMP WITH TIME ZONE,
    usage_count BIGINT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- API request logs
CREATE TABLE IF NOT EXISTS api_request_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    api_key_id UUID REFERENCES api_keys(id) ON DELETE SET NULL,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    method VARCHAR(10) NOT NULL,
    path TEXT NOT NULL,
    query_params JSONB,
    request_headers JSONB,
    response_status INTEGER NOT NULL,
    response_time_ms INTEGER,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Webhook configurations
CREATE TABLE IF NOT EXISTS webhooks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    name VARCHAR(200) NOT NULL,
    url TEXT NOT NULL,
    secret VARCHAR(255),
    events TEXT[] NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    retry_config JSONB DEFAULT '{"max_retries": 3, "retry_delay": 60}',
    last_triggered_at TIMESTAMP WITH TIME ZONE,
    success_count BIGINT DEFAULT 0,
    failure_count BIGINT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- Audit and Security Schema
-- =============================================================================

-- Security events log
CREATE TABLE IF NOT EXISTS security_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    event_type VARCHAR(50) NOT NULL,
    severity VARCHAR(10) DEFAULT 'info' CHECK (severity IN ('info', 'warning', 'error', 'critical')),
    description TEXT NOT NULL,
    ip_address INET,
    user_agent TEXT,
    metadata JSONB DEFAULT '{}',
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolved_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- System audit log
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID NOT NULL,
    action VARCHAR(50) NOT NULL,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- Indexes for Performance
-- =============================================================================

-- User indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_email ON users USING btree (email);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_username ON users USING btree (username);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_status ON users USING btree (status) WHERE status != 'deleted';
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_created_at ON users USING btree (created_at);

-- Session indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_sessions_user_id ON user_sessions USING btree (user_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_sessions_token_hash ON user_sessions USING btree (token_hash);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_sessions_expires_at ON user_sessions USING btree (expires_at);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_sessions_active ON user_sessions USING btree (is_active, expires_at) WHERE is_active = true;

-- Project indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_projects_owner_id ON projects USING btree (owner_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_projects_slug ON projects USING btree (slug);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_projects_status ON projects USING btree (status);

-- Task indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tasks_project_id ON tasks USING btree (project_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tasks_assignee_id ON tasks USING btree (assignee_id) WHERE assignee_id IS NOT NULL;
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tasks_status ON tasks USING btree (status);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tasks_due_date ON tasks USING btree (due_date) WHERE due_date IS NOT NULL;
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tasks_created_at ON tasks USING btree (created_at);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tasks_search_vector ON tasks USING gin (search_vector);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tasks_tags ON tasks USING gin (tags);

-- Notification indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_notifications_user_id ON notifications USING btree (user_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_notifications_status ON notifications USING btree (status);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_notifications_scheduled_for ON notifications USING btree (scheduled_for) WHERE status = 'pending';
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_notifications_read_at ON notifications USING btree (read_at);

-- File indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_files_uploaded_by ON files USING btree (uploaded_by);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_files_file_hash ON files USING btree (file_hash);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_file_associations_entity ON file_associations USING btree (entity_type, entity_id);

-- API and audit indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_api_request_logs_created_at ON api_request_logs USING btree (created_at);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_api_request_logs_api_key_id ON api_request_logs USING btree (api_key_id) WHERE api_key_id IS NOT NULL;
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_audit_logs_entity ON audit_logs USING btree (entity_type, entity_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_audit_logs_created_at ON audit_logs USING btree (created_at);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_security_events_created_at ON security_events USING btree (created_at);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_security_events_severity ON security_events USING btree (severity);

-- =============================================================================
-- Full-Text Search Setup
-- =============================================================================

-- Update search vector for tasks
CREATE OR REPLACE FUNCTION update_task_search_vector()
RETURNS TRIGGER AS $$
BEGIN
    NEW.search_vector := to_tsvector('english', 
        COALESCE(NEW.title, '') || ' ' || 
        COALESCE(NEW.description, '') || ' ' ||
        COALESCE(array_to_string(NEW.tags, ' '), '')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_task_search_vector_trigger
    BEFORE INSERT OR UPDATE ON tasks
    FOR EACH ROW EXECUTE FUNCTION update_task_search_vector();

-- =============================================================================
-- Triggers for Audit and Timestamps
-- =============================================================================

-- Updated_at triggers
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_sessions_updated_at BEFORE UPDATE ON user_sessions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_roles_updated_at BEFORE UPDATE ON roles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON projects
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_files_updated_at BEFORE UPDATE ON files
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_api_keys_updated_at BEFORE UPDATE ON api_keys
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_webhooks_updated_at BEFORE UPDATE ON webhooks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- Insert Default Data
-- =============================================================================

-- Default roles
INSERT INTO roles (name, description, permissions, is_system_role) VALUES
    ('super_admin', 'Super Administrator with full system access', '["*"]', true),
    ('admin', 'Administrator with project management access', '["projects.*", "users.read", "users.update"]', true),
    ('project_manager', 'Project Manager with full project access', '["projects.manage", "tasks.*", "users.read"]', true),
    ('developer', 'Developer with task management access', '["projects.read", "tasks.*"]', true),
    ('viewer', 'Read-only access to assigned projects', '["projects.read", "tasks.read"]', true)
ON CONFLICT (name) DO NOTHING;

-- Default notification types
INSERT INTO notification_types (name, description, template, default_channels) VALUES
    ('task_assigned', 'Task assigned to user', '{"title": "Task Assigned", "message": "You have been assigned to task: {{task_title}}"}', '{"web", "email"}'),
    ('task_completed', 'Task marked as completed', '{"title": "Task Completed", "message": "Task {{task_title}} has been completed"}', '{"web"}'),
    ('project_invitation', 'Invitation to join project', '{"title": "Project Invitation", "message": "You have been invited to join {{project_name}}"}', '{"web", "email"}'),
    ('due_date_reminder', 'Task due date reminder', '{"title": "Due Date Reminder", "message": "Task {{task_title}} is due on {{due_date}}"}', '{"web", "email"}'),
    ('security_alert', 'Security-related notifications', '{"title": "Security Alert", "message": "{{alert_message}}"}', '{"web", "email"}')
ON CONFLICT (name) DO NOTHING;

-- =============================================================================
-- Database Maintenance Functions
-- =============================================================================

-- Clean up expired sessions
CREATE OR REPLACE FUNCTION cleanup_expired_sessions()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM user_sessions 
    WHERE expires_at < CURRENT_TIMESTAMP OR is_active = false;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Clean up expired tokens
CREATE OR REPLACE FUNCTION cleanup_expired_tokens()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM password_reset_tokens 
    WHERE expires_at < CURRENT_TIMESTAMP OR used_at IS NOT NULL;
    
    DELETE FROM email_verification_tokens 
    WHERE expires_at < CURRENT_TIMESTAMP OR verified_at IS NOT NULL;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Partition old audit logs
CREATE OR REPLACE FUNCTION partition_old_audit_logs(retention_days INTEGER DEFAULT 365)
RETURNS INTEGER AS $$
DECLARE
    cutoff_date TIMESTAMP WITH TIME ZONE;
    archived_count INTEGER;
BEGIN
    cutoff_date := CURRENT_TIMESTAMP - (retention_days || ' days')::INTERVAL;
    
    -- Move old audit logs to archive table (create if not exists)
    CREATE TABLE IF NOT EXISTS audit_logs_archive (
        LIKE audit_logs INCLUDING ALL
    );
    
    WITH moved_rows AS (
        DELETE FROM audit_logs 
        WHERE created_at < cutoff_date
        RETURNING *
    )
    INSERT INTO audit_logs_archive SELECT * FROM moved_rows;
    
    GET DIAGNOSTICS archived_count = ROW_COUNT;
    
    RETURN archived_count;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Performance Analysis Views
-- =============================================================================

-- Active users summary
CREATE OR REPLACE VIEW active_users_summary AS
SELECT 
    COUNT(*) as total_users,
    COUNT(CASE WHEN status = 'active' THEN 1 END) as active_users,
    COUNT(CASE WHEN last_login_at > CURRENT_TIMESTAMP - INTERVAL '30 days' THEN 1 END) as users_active_30d,
    COUNT(CASE WHEN last_login_at > CURRENT_TIMESTAMP - INTERVAL '7 days' THEN 1 END) as users_active_7d,
    COUNT(CASE WHEN created_at > CURRENT_TIMESTAMP - INTERVAL '30 days' THEN 1 END) as new_users_30d
FROM users
WHERE status != 'deleted';

-- Project statistics view
CREATE OR REPLACE VIEW project_statistics AS
SELECT 
    p.id,
    p.name,
    p.status,
    COUNT(DISTINCT pm.user_id) as member_count,
    COUNT(DISTINCT t.id) as total_tasks,
    COUNT(CASE WHEN t.status = 'done' THEN 1 END) as completed_tasks,
    COUNT(CASE WHEN t.status IN ('todo', 'in_progress') THEN 1 END) as active_tasks,
    COUNT(CASE WHEN t.due_date < CURRENT_TIMESTAMP AND t.status != 'done' THEN 1 END) as overdue_tasks,
    p.created_at,
    p.updated_at
FROM projects p
LEFT JOIN project_members pm ON p.id = pm.project_id AND pm.is_active = true
LEFT JOIN tasks t ON p.id = t.project_id
WHERE p.status = 'active'
GROUP BY p.id, p.name, p.status, p.created_at, p.updated_at;

-- Task completion trends view
CREATE OR REPLACE VIEW task_completion_trends AS
SELECT 
    DATE_TRUNC('week', completed_at) as week_start,
    COUNT(*) as tasks_completed,
    AVG(actual_hours) as avg_hours,
    COUNT(DISTINCT assignee_id) as unique_assignees
FROM tasks
WHERE status = 'done' 
    AND completed_at IS NOT NULL 
    AND completed_at >= CURRENT_TIMESTAMP - INTERVAL '12 weeks'
GROUP BY DATE_TRUNC('week', completed_at)
ORDER BY week_start;

COMMIT;

-- =============================================================================
-- Migration Complete
-- =============================================================================

-- Log migration completion
DO $$
BEGIN
    RAISE NOTICE 'Database migration completed successfully!';
    RAISE NOTICE 'Created % tables with indexes, triggers, and default data', 
        (SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public');
END
$$;