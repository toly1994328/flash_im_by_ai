import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button, Input, message } from 'antd';
import { LockOutlined, UserOutlined, ThunderboltOutlined } from '@ant-design/icons';
import { login } from '../../api/auth';
import { useAuth } from '../../auth/AuthContext';

export default function LoginPage() {
  const [phone, setPhone] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();
  const auth = useAuth();

  const handleLogin = async () => {
    if (!phone || !password) {
      message.warning('请输入账号和密码');
      return;
    }
    setLoading(true);
    try {
      const res = await login(phone, password);
      auth.login(res.token);
      message.success('登录成功');
      navigate('/apps', { replace: true });
    } catch (e: unknown) {
      message.error(e instanceof Error ? e.message : '登录失败');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-slate-50 to-blue-50">
      <div className="w-[380px] bg-white rounded-2xl shadow-lg shadow-blue-100/50 p-8">
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-12 h-12 bg-blue-500 rounded-xl mb-4">
            <ThunderboltOutlined className="text-white text-xl" />
          </div>
          <h1 className="text-xl font-semibold text-gray-800">闪讯管理后台</h1>
          <p className="text-sm text-gray-400 mt-1">管理员专属入口</p>
        </div>
        <div className="space-y-4">
          <Input
            size="large"
            prefix={<UserOutlined className="text-gray-300" />}
            placeholder="手机号 / 邮箱"
            value={phone}
            onChange={(e) => setPhone(e.target.value)}
            onPressEnter={handleLogin}
            className="rounded-lg"
          />
          <Input.Password
            size="large"
            prefix={<LockOutlined className="text-gray-300" />}
            placeholder="密码"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            onPressEnter={handleLogin}
            className="rounded-lg"
          />
          <Button
            type="primary"
            size="large"
            block
            loading={loading}
            onClick={handleLogin}
            className="rounded-lg h-11 font-medium mt-2"
          >
            登 录
          </Button>
        </div>
      </div>
    </div>
  );
}
