import { NavLink } from 'react-router-dom';
import { useTranslation } from 'react-i18next';

export function Sidebar() {
  const { t } = useTranslation();

  const navItems = [
    { path: '/dashboard', label: t('dashboard.title') },
    { path: '/appointments', label: t('appointments.title') },
  ];

  return (
    <aside className='w-64 border-r border-secondary-200 bg-white'>
      <nav className='flex flex-col gap-2 p-4'>
        {navItems.map(item => (
          <NavLink
            key={item.path}
            to={item.path}
            className={({ isActive }) =>
              `rounded-md px-4 py-2 text-sm font-medium transition-colors ${
                isActive
                  ? 'bg-primary-100 text-primary-700'
                  : 'text-secondary-600 hover:bg-secondary-100'
              }`
            }
          >
            {item.label}
          </NavLink>
        ))}
      </nav>
    </aside>
  );
}
