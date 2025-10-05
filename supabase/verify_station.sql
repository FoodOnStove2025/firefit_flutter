-- Check if DEMO station exists
SELECT id, name, code FROM stations WHERE code = 'DEMO';

-- If no results, insert a demo station
INSERT INTO stations (name, code, address, city, state, zip) 
VALUES ('Demo Station', 'DEMO', '123 Main St', 'Demo City', 'DC', '12345')
ON CONFLICT (code) DO NOTHING;