import { Layout, Menu } from 'antd';
import { AppstoreOutlined, MessageOutlined, UserOutlined, TeamOutlined, RocketOutlined } from '@ant-design/icons';
import { useNavigate, useLocation } from 'react-router-dom';

const { Sider } = Layout;

export default function Sidebar() {
  const navigate = useNavigate();
  const location = useLocation();

  const menuItems = [
    {
      key: 'app-center',
      icon: <RocketOutlined />,
      label: '应用中心',
      children: [
        { key: '/apps', icon: <AppstoreOutlined />, label: '应用列表' },
      ],
    },
    {
      key: 'im-admin',
      icon: <MessageOutlined />,
      label: 'IM 管理',
      children: [
        { key: '/im/users', icon: <UserOutlined />, label: '用户' },
        { key: '/im/conversations', icon: <TeamOutlined />, label: '会话' },
      ],
    },
  ];

  return (
    <Sider
      width={220}
      className="shadow-sm"
      style={{ background: '#fff', borderRight: '1px solid #f0f0f0' }}
    >
      <div style={{ height: 48, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, borderBottom: '1px solid #f0f0f0' }}>
        <img src="/logo.png" alt="logo" style={{ width: 22, height: 22, borderRadius: 4 }} />
        <span style={{ fontSize: 14, fontWeight: 500, color: '#333' }}>闪讯管理</span>
      </div>
      <Menu
        mode="inline"
        selectedKeys={[location.pathname]}
        defaultOpenKeys={['app-center', 'im-admin']}
        items={menuItems}
        onClick={({ key }) => navigate(key)}
        style={{ border: 'none', fontSize: 13 }}
      />
    </Sider>
  );
}
