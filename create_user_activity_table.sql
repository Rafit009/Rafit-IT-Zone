-- Create a function to create the user_activity table if it doesn't exist
CREATE OR REPLACE FUNCTION create_user_activity_table_if_not_exists()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  -- Check if the user_activity table exists
  IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'user_activity') THEN
      -- Create the user_activity table
      CREATE TABLE public.user_activity (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
          action TEXT NOT NULL,
          timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
          CONSTRAINT fk_user
              FOREIGN KEY(user_id) 
              REFERENCES auth.users(id)
              ON DELETE CASCADE
      );

      -- Enable Row Level Security
      ALTER TABLE public.user_activity ENABLE ROW LEVEL SECURITY;

      -- Create policies
      CREATE POLICY "Users can view their own activity."
          ON public.user_activity FOR SELECT
          USING (auth.uid() = user_id);

      CREATE POLICY "Users can insert their own activity."
          ON public.user_activity FOR INSERT
          WITH CHECK (auth.uid() = user_id);
  END IF;
END;
$$;

-- Execute the function
SELECT create_user_activity_table_if_not_exists();

