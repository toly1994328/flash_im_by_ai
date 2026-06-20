import { Layout, Button, Breadcrumb } from 'antd';
import { LogoutOutlined } from '@ant-design/icons';
import { Outlet, useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../../auth/AuthContext';
import Sidebar from './Sidebar';

const { Content, Header } = Layout;

const breadcrumbMap: Record<string, string> = {
  '/apps': '应用列表',
  '/im/users': '用户管理',
  '/im/conversations': '会话管理',
};

export default function AppLayout() {
  const { logout } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const handleLogout = () => {
    logout();
    navigate('/login', { replace: true });
  };

  const pathParts = location.pathname.split('/').filter(Boolean);
  const breadcrumbItems = pathParts.map((_, index) => {
    const path = '/' + pathParts.slice(0, index + 1).join('/');
    return { title: breadcrumbMap[path] || pathParts[index] };
  });

  return (
    <Layout style={{ minHeight: '100vh' }}>
      <Sidebar />
      <Layout>
        <Header className="!bg-white" style={{ background: '#fff', height: 48, lineHeight: '48px', padding: '0 20px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', borderBottom: '1px solid #f0f0f0' }}>
          <Breadcrumb items={breadcrumbItems} />
          <Button
            type="text"
            icon={<LogoutOutlined />}
            onClick={handleLogout}
            className="text-gray-400 hover:text-gray-600"
          >
            退出
          </Button>
        </Header>
        <Content style={{ padding: 20, background: '#f7f8fa' }}>
          <Outlet />
        </Content>
      </Layout>
    </Layout>
  );
}
