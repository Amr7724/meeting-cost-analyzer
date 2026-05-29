-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create workspaces table
CREATE TABLE workspaces (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  currency VARCHAR(3) DEFAULT 'USD',
  subscription_status VARCHAR(50) DEFAULT 'free',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create users table
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  role VARCHAR(50) DEFAULT 'editor',
  full_name TEXT NOT NULL,
  email TEXT NOT NULL,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create team salaries table
CREATE TABLE team_salaries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  employee_email TEXT NOT NULL,
  role_title TEXT,
  hourly_rate DECIMAL(10, 2) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(workspace_id, employee_email)
);

-- Create synced meetings table
CREATE TABLE synced_meetings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  calendar_event_id TEXT NOT NULL,
  title TEXT NOT NULL,
  duration_minutes INTEGER NOT NULL,
  attendee_count INTEGER NOT NULL,
  attendee_emails TEXT[] DEFAULT ARRAY[]::TEXT[],
  calculated_cost DECIMAL(10, 2) NOT NULL,
  scheduled_at TIMESTAMP WITH TIME ZONE NOT NULL,
  synced_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(workspace_id, calendar_event_id)
);

-- Create oauth_tokens table
CREATE TABLE oauth_tokens (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  provider VARCHAR(50) NOT NULL,
  access_token TEXT NOT NULL,
  refresh_token TEXT,
  expires_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, provider)
);

-- Enable RLS
ALTER TABLE workspaces ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_salaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE synced_meetings ENABLE ROW LEVEL SECURITY;
ALTER TABLE oauth_tokens ENABLE ROW LEVEL SECURITY;

-- Workspaces RLS
CREATE POLICY "Users can read their own workspace" ON workspaces FOR SELECT USING (id IN (SELECT workspace_id FROM users WHERE id = auth.uid()));

-- Users RLS
CREATE POLICY "Users can read users in their workspace" ON users FOR SELECT USING (workspace_id = (SELECT workspace_id FROM users WHERE id = auth.uid() LIMIT 1));
CREATE POLICY "Users can update their own profile" ON users FOR UPDATE USING (id = auth.uid());

-- Team salaries RLS
CREATE POLICY "Users can read team salaries in their workspace" ON team_salaries FOR SELECT USING (workspace_id = (SELECT workspace_id FROM users WHERE id = auth.uid() LIMIT 1));
CREATE POLICY "Users can manage team salaries in their workspace" ON team_salaries FOR INSERT WITH CHECK (workspace_id = (SELECT workspace_id FROM users WHERE id = auth.uid() LIMIT 1));
CREATE POLICY "Users can update team salaries in their workspace" ON team_salaries FOR UPDATE USING (workspace_id = (SELECT workspace_id FROM users WHERE id = auth.uid() LIMIT 1));

-- Synced meetings RLS
CREATE POLICY "Users can read synced meetings in their workspace" ON synced_meetings FOR SELECT USING (workspace_id = (SELECT workspace_id FROM users WHERE id = auth.uid() LIMIT 1));
CREATE POLICY "Users can insert synced meetings in their workspace" ON synced_meetings FOR INSERT WITH CHECK (workspace_id = (SELECT workspace_id FROM users WHERE id = auth.uid() LIMIT 1));

-- OAuth tokens RLS
CREATE POLICY "Users can only access their own OAuth tokens" ON oauth_tokens FOR ALL USING (user_id = auth.uid());
