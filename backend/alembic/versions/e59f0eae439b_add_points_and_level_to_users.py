"""add points and level to users

Revision ID: e59f0eae439b
Revises: 1e10053625a9
Create Date: 2025-11-24 18:38:10.356059

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'e59f0eae439b'
down_revision: Union[str, None] = '1e10053625a9'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
