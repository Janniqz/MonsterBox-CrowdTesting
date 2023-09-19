# Installation

### 1. Prerequisites
- [NodeJS](https://nodejs.org/en/download) (Built with v18.17.1)
- [Supabase Account & Project](https://supabase.com/)

### 2. Supabase Setup
To get Supabase ready, follow the following steps:
1. Database Setup
   1. Log into your Supabase Account and head to the SQL Editor 
   2. Copy the Contents of the provided ***supabase_install_script.sql*** and paste it into the Editor
   3. Execute
2. Configuration
   1. In Supabase go to Authentication -> URL Configuration
   2. Update the Site URL to http://localhost:5173/auth/callback (Dev Server)
      1. For production deployment change this to the hosting URL

### 3. Project Configuration
The Project needs some configuration to work correctly:
1. Create a copy (/ rename) the included .env.example file and name it .env
2. Fill out the included fields with the values from your Supabase project
    1. Values can be found under Project Settings --> API

Additionally, the required packages should be installed by executing `npm install` in the project directory.

# Running the Application

### 1. Development
When running the application locally / in a development environment, it can be started with the `npm run dev` command.<br>
This will start a local instance of the application reachable via http://localhost:5173/ .

### 2. Production
For testing the production version of the application locally, `npm run preview` can be used.<br>

When actually packaging the application, `npm run build` should be used.<br>
After packaging, it can then be run via `node build` (provided the build folder is still named build)
