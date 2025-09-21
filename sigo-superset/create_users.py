from superset import app
from superset.security.manager import SupersetSecurityManager

def create_admin():
    from flask_appbuilder.security.sqla.manager import SecurityManager
    sm = SecurityManager(app)
    sm.add_user(
        username="admin",
        first_name="Admin",
        last_name="User",
        email="admin@tudominio.com",
        role=sm.find_role("Admin"),
        password="contraseña_admin_segura"
    )

if __name__ == "__main__":
    create_admin()
