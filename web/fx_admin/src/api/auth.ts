export interface LoginResponse {
  token: string;
  user_id: number;
  has_password: boolean;
}

export async function login(phone: string, password: string): Promise<LoginResponse> {
  const res = await fetch('/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ phone, credential: password, type: 'password' }),
  });
  if (!res.ok) {
    const data = await res.json().catch(() => ({}));
    throw new Error(data.message || '账号或密码错误');
  }
  const data: LoginResponse = await res.json();
  if (data.user_id !== 1 && data.user_id !== 2) {
    throw new Error('无管理员权限');
  }
  return data;
}
