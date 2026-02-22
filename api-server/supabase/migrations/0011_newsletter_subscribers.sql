-- Newsletter subscribers table
CREATE TABLE IF NOT EXISTS newsletter_subscribers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text NOT NULL UNIQUE,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'unsubscribed')),
  source text DEFAULT 'website',
  resubscribed_at timestamptz,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX idx_newsletter_status ON newsletter_subscribers (status);
CREATE INDEX idx_newsletter_email ON newsletter_subscribers (email);
