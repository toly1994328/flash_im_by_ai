import { Layout, Button } from 'antd';
import { LogoutOutlined } from '@ant-design/icons';
import { Outlet, useNavigate } from 'react-router-dom';
import { useAuth } from '../../auth/AuthContext';
import Sidebar from './Sidebar';

const { Content, Header } = Layout;

export default function AppLayout() {
  const { logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate('/login', { replace: true });
  };

  return (
    <Layout style={{ minHeight: '100vh' }}>
      <Sidebar />
      <Layout>
        <Header style={{ background: '#fff', padding: '0 24px', display: 'flex', justifyContent: 'flex-end', alignItems: 'center', borderBottom: '1px solid #f0f0f0' }}>
          <Button type="text" icon={<LogoutOutlined />} onClick={handleLogout}>
            退出
          </Button>
        </Header>
        <Content style={{ padding: 24, background: '#f5f5f5' }}>
          <div style={{ background: '#fff', padding: 24, borderRadius: 8 }}>
            <Outlet />
          </div>
        </Content>
      </Layout>
    </Layout>
  );
}
