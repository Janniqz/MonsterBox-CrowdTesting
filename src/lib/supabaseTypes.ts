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
      feedback: {
        Row: {
          created_at: string
          feedback_id: number
          feedback_text: string
          promotion_id: number
          user_id: string | null
        }
        Insert: {
          created_at?: string
          feedback_id?: number
          feedback_text: string
          promotion_id: number
          user_id?: string | null
        }
        Update: {
          created_at?: string
          feedback_id?: number
          feedback_text?: string
          promotion_id?: number
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "feedback_promotion_id_fkey"
            columns: ["promotion_id"]
            referencedRelation: "promotions"
            referencedColumns: ["promotion_id"]
          },
          {
            foreignKeyName: "feedback_promotion_id_fkey"
            columns: ["promotion_id"]
            referencedRelation: "promotion_admin_info"
            referencedColumns: ["promotion_id"]
          },
          {
            foreignKeyName: "feedback_promotion_id_fkey"
            columns: ["promotion_id"]
            referencedRelation: "promotion_key_summary"
            referencedColumns: ["promotion_id"]
          },
          {
            foreignKeyName: "feedback_user_id_fkey"
            columns: ["user_id"]
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          }
        ]
      }
      keys: {
        Row: {
          claimed_by: string | null
          created_at: string | null
          feedback_id: number | null
          key: string
          key_id: number
          promotion_id: number
        }
        Insert: {
          claimed_by?: string | null
          created_at?: string | null
          feedback_id?: number | null
          key?: string
          key_id?: number
          promotion_id: number
        }
        Update: {
          claimed_by?: string | null
          created_at?: string | null
          feedback_id?: number | null
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
            foreignKeyName: "keys_feedback_id_fkey"
            columns: ["feedback_id"]
            referencedRelation: "feedback"
            referencedColumns: ["feedback_id"]
          },
          {
            foreignKeyName: "keys_promotion_id_fkey"
            columns: ["promotion_id"]
            referencedRelation: "promotions"
            referencedColumns: ["promotion_id"]
          },
          {
            foreignKeyName: "keys_promotion_id_fkey"
            columns: ["promotion_id"]
            referencedRelation: "promotion_admin_info"
            referencedColumns: ["promotion_id"]
          },
          {
            foreignKeyName: "keys_promotion_id_fkey"
            columns: ["promotion_id"]
            referencedRelation: "promotion_key_summary"
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
      promotion_admin_info: {
        Row: {
          claimed_keys: number | null
          created_at: string | null
          description: string | null
          expiration_date: string | null
          feedback_ratio: number | null
          name: string | null
          promotion_id: number | null
          total_keys: number | null
        }
        Relationships: []
      }
      promotion_key_summary: {
        Row: {
          promotion_id: number | null
          total_keys: number | null
          unclaimed_keys: number | null
        }
        Relationships: []
      }
    }
    Functions: {
      add_feedback: {
        Args: {
          user_id: string
          target_promotion_id: number
          target_key_id: number
          feedback_text: string
        }
        Returns: boolean
      }
      claim_key: {
        Args: {
          user_id: string
          target_promotion_id: number
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
        promotion_id: number
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
