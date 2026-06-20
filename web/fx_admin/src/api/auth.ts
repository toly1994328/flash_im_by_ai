const BASE = '/api';

export interface LoginResponse {
  token: string;
  user_id: number;
  has_password: boolean;
}

export async function login(phone: string, password: string): Promise<LoginResponse> {
  const res = await fetch(`${BASE}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ phone, code: password, login_type: 'password' }),
  });
  if (!res.ok) {
    const data = await res.json().catch(() => ({}));
    throw new Error(data.message || '登录失败');
  }
  const data: LoginResponse = await res.json();
  if (data.user_id !== 1) {
    throw new Error('无管理员权限');
  }
  return data;
}
