INSERT INTO subscription_plans (code, name, storage_bytes, features, price_cents, period_days)
VALUES ('cloud_pro', 'Cloud Pro', 1073741824, '{"oss_upload": true}'::jsonb, 99, 30)
ON CONFLICT (code) DO NOTHING;

INSERT INTO redeem_codes (code, plan_id, duration_days, max_uses)
SELECT 'TEST-PRO-2026', id, 30, 10 FROM subscription_plans WHERE code = 'cloud_pro'
ON CONFLICT (code) DO NOTHING;
