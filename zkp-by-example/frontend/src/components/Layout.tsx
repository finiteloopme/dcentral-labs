import { Link, Outlet } from 'react-router-dom';

function Layout() {
  return (
    <div>
      <nav>
        <Link to="/">Home</Link>
        <Link to="/admin">Admin</Link>
      </nav>

      <hr />

      <Outlet />
    </div>
  );
}

export default Layout;
