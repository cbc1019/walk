-- =====================================================
-- 병원 걷기 챌린지 - Supabase 초기 설정 SQL
-- Supabase → SQL Editor에 붙여넣고 실행하세요
-- =====================================================

-- 1. 걸음 수 테이블 (직원별 날짜별 1행)
CREATE TABLE IF NOT EXISTS steps (
  id          BIGSERIAL PRIMARY KEY,
  employee_id TEXT    NOT NULL,
  name        TEXT    NOT NULL,
  date        DATE    NOT NULL,
  steps       INTEGER NOT NULL DEFAULT 0,
  updated_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (employee_id, date)
);

-- 2. 챌린지 기간 테이블
CREATE TABLE IF NOT EXISTS challenge_period (
  id         INTEGER PRIMARY KEY DEFAULT 1,
  name       TEXT DEFAULT '걷기 챌린지',
  start_date DATE,
  end_date   DATE,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. 보안 정책 (내부 직원 전용이므로 전체 허용)
ALTER TABLE steps            ENABLE ROW LEVEL SECURITY;
ALTER TABLE challenge_period ENABLE ROW LEVEL SECURITY;

CREATE POLICY "allow_all_steps"  ON steps            FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_period" ON challenge_period FOR ALL TO anon USING (true) WITH CHECK (true);

-- 4. 기간 누적 랭킹 함수 (서버에서 집계 → 빠름)
CREATE OR REPLACE FUNCTION get_period_ranking(p_start DATE, p_end DATE)
RETURNS TABLE(employee_id TEXT, name TEXT, total_steps BIGINT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT s.employee_id,
         s.name,
         SUM(s.steps)::BIGINT AS total_steps
  FROM   steps s
  WHERE  s.date >= p_start
    AND  s.date <= p_end
  GROUP  BY s.employee_id, s.name
  ORDER  BY total_steps DESC;
END;
$$;
