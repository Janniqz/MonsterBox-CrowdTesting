export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json }
  | Json[]

export type User = {
  id: string,
  isAdmin: boolean,
}

export interface Database {
  public: {
    Tables: {
      profiles: {
        Row: {
          id: string
          role: string | null
          updated_at: string | null
        }
        Insert: {
          id: string
          role?: string | null
          updated_at?: string | null
        }
        Update: {
          id?: string
          role?: string | null
          updated_at?: string | null
        }
      }
    }
  }
}
