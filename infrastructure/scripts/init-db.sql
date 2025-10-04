-- Create langfuse database
CREATE DATABASE langfuse;

-- Grant permissions
GRANT ALL PRIVILEGES ON DATABASE llmplatform TO llmuser;
GRANT ALL PRIVILEGES ON DATABASE langfuse TO llmuser;

-- Connect to llmplatform database and enable extensions
\c llmplatform;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgvector";

-- Connect to langfuse database and enable extensions
\c langfuse;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";


