-- Create a function to create the profiles table if it doesn't exist
CREATE OR REPLACE FUNCTION create_profiles_if_not_exists()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    -- Check if the profiles table exists
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'profiles') THEN
        -- Create the profiles table
        CREATE TABLE profiles (
            id UUID PRIMARY KEY REFERENCES auth.users(id),
            bio TEXT,
            website TEXT,
            avatar_url TEXT,
            updated_at TIMESTAMP WITH TIME ZONE,
            CONSTRAINT fk_user
                FOREIGN KEY(id) 
                REFERENCES auth.users(id)
                ON DELETE CASCADE
        );

        -- Enable Row Level Security
        ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

        -- Create policies
        CREATE POLICY "Public profiles are viewable by everyone."
            ON profiles FOR SELECT
            USING ( true );

        CREATE POLICY "Users can insert their own profile."
            ON profiles FOR INSERT
            WITH CHECK ( auth.uid() = id );

        CREATE POLICY "Users can update own profile."
            ON profiles FOR UPDATE
            USING ( auth.uid() = id );
    END IF;
END;
$$;

