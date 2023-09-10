export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {
      keys: {
        Row: {
          claimed: boolean
          claimed_by: string | null
          created_at: string | null
          feedback_given: boolean
          key: string
          key_id: number
          promotion_id: number
        }
        Insert: {
          claimed: boolean
          claimed_by?: string | null
          created_at?: string | null
          feedback_given?: boolean
          key?: string
          key_id?: number
          promotion_id: number
        }
        Update: {
          claimed?: boolean
          claimed_by?: string | null
          created_at?: string | null
          feedback_given?: boolean
          key?: string
          key_id?: number
          promotion_id?: number
        }
        Relationships: [
          {
            foreignKeyName: "keys_claimed_by_fkey"
            columns: ["claimed_by"]
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "keys_promotion_id_fkey"
            columns: ["promotion_id"]
            referencedRelation: "promotions"
            referencedColumns: ["promotion_id"]
          }
        ]
      }
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
        Relationships: [
          {
            foreignKeyName: "profiles_id_fkey"
            columns: ["id"]
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      promotions: {
        Row: {
          created_at: string | null
          description: string | null
          expiration_date: string | null
          name: string
          promotion_id: number
        }
        Insert: {
          created_at?: string | null
          description?: string | null
          expiration_date?: string | null
          name: string
          promotion_id?: number
        }
        Update: {
          created_at?: string | null
          description?: string | null
          expiration_date?: string | null
          name?: string
          promotion_id?: number
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      claim_key: {
        Args: {
          promotion_id: number
        }
        Returns: Database["public"]["CompositeTypes"]["claim_info"]
      }
      get_awaiting_feedback: {
        Args: Record<PropertyKey, never>
        Returns: Database["public"]["CompositeTypes"]["feedback_info"][]
      }
      get_redeemed: {
        Args: Record<PropertyKey, never>
        Returns: Database["public"]["CompositeTypes"]["redeemed_info"][]
      }
      get_running_promotions: {
        Args: Record<PropertyKey, never>
        Returns: Database["public"]["CompositeTypes"]["promotion_info"][]
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      claim_info: {
        success: boolean
        error_message: string
        claimed_key: string
      }
      feedback_info: {
        promotion_name: string
        key_id: number
      }
      promotion_info: {
        promotion_id: number
        promotion_name: string
        promotion_description: string
        promotion_expiry_date: string
        promotion_claimed: boolean
        promotion_total_keys: number
        promotion_unclaimed_keys: number
      }
      redeemed_info: {
        promotion_name: string
        key: string
        feedback_given: boolean
      }
    }
  }
}
