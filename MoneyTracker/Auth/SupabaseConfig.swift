import Foundation

// MARK: - SupabaseConfig
//
// Coordinate del progetto Supabase. La chiave qui sotto è la "anon/public key":
// per design è pensata per stare nel client (app, sito, ecc.) e viene esposta
// pubblicamente — la protezione reale dei dati è demandata alle Row Level
// Security policies del database (ogni utente vede/modifica solo le proprie
// righe). Per questo motivo il file NON è nel .gitignore.
//
// Da non confondere con la "service_role key", che bypassa RLS e non deve
// MAI comparire nel codice client-side.

enum SupabaseConfig {
    static let url = URL(string: "https://zblpzufsikxhuzdtcucg.supabase.co")!
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpibHB6dWZzaWt4aHV6ZHRjdWNnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI4MTE1MzcsImV4cCI6MjA5ODM4NzUzN30.lezj5CD6yYjSK2-HeGSjU1kaE29G3B_ojiFhSz-8pgg"
}
