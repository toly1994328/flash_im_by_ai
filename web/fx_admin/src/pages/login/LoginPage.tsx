import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button, Input, Card, message } from 'antd';
import { LockOutlined, UserOutlined } from '@ant-design/icons';
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
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <Card className="w-[360px] shadow-md" title={null}>
        <div className="text-center mb-6">
          <h1 className="text-xl font-semibold text-gray-800">闪讯管理后台</h1>
          <p className="text-sm text-gray-400 mt-1">仅限管理员登录</p>
        </div>
        <div className="space-y-4">
          <Input
            size="large"
            prefix={<UserOutlined className="text-gray-400" />}
            placeholder="手机号 / 邮箱"
            value={phone}
            onChange={(e) => setPhone(e.target.value)}
            onPressEnter={handleLogin}
          />
          <Input.Password
            size="large"
            prefix={<LockOutlined className="text-gray-400" />}
            placeholder="密码"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            onPressEnter={handleLogin}
          />
          <Button
            type="primary"
            size="large"
            block
            loading={loading}
            onClick={handleLogin}
          >
            登录
          </Button>
        </div>
      </Card>
    </div>
  );
}
