import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import Employees from './Employees';
import { getDocs, addDoc, deleteDoc } from 'firebase/firestore';

// ─── Mocks ────────────────────────────────────────────────────────────────────

vi.mock('firebase/firestore', () => ({
  collection: vi.fn(() => 'mock-collection'),
  getDocs: vi.fn(),
  addDoc: vi.fn(),
  deleteDoc: vi.fn(),
  doc: vi.fn(() => 'mock-doc-ref'),
}));

vi.mock('../firebase', () => ({ db: {} }));

// ─── Helpers ──────────────────────────────────────────────────────────────────

function mockSnapshot(employees) {
  return {
    docs: employees.map((emp) => ({
      id: emp.id,
      data: () => ({ username: emp.username, name: emp.name, email: emp.email }),
    })),
  };
}

const EMPLOYEES = [
  { id: 'e1', username: 'jsmith',  name: 'John Smith', email: 'john@example.com' },
  { id: 'e2', username: 'jdoe',    name: 'Jane Doe',   email: 'jane@example.com' },
  { id: 'e3', username: 'bwilson', name: 'Bob Wilson', email: 'bob@example.com'  },
];

// ─── Tests ────────────────────────────────────────────────────────────────────

describe('Employees', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    getDocs.mockResolvedValue(mockSnapshot(EMPLOYEES));
  });

  // ── 1. fetchEmployees ────────────────────────────────────────────────────────
  describe('fetchEmployees', () => {
    it('renders all employees returned by Firestore', async () => {
      render(<Employees />);
      await waitFor(() => {
        expect(screen.getByText('@jsmith')).toBeInTheDocument();
        expect(screen.getByText('@jdoe')).toBeInTheDocument();
        expect(screen.getByText('@bwilson')).toBeInTheDocument();
      });
    });

    it('shows the correct team member count', async () => {
      render(<Employees />);
      await waitFor(() =>
        expect(screen.getByText('3 team members')).toBeInTheDocument()
      );
    });

    it('displays an error message when Firestore fetch fails', async () => {
      getDocs.mockRejectedValue(new Error('Network error'));
      render(<Employees />);
      await waitFor(() =>
        expect(screen.getByText(/Failed to load employees/)).toBeInTheDocument()
      );
    });

    it('shows empty state when no employees exist', async () => {
      getDocs.mockResolvedValue(mockSnapshot([]));
      render(<Employees />);
      await waitFor(() =>
        expect(screen.getByText('No employees found.')).toBeInTheDocument()
      );
    });
  });

  // ── 2. handleCreate ──────────────────────────────────────────────────────────
  describe('handleCreate', () => {
    const openModal = async () => {
      await waitFor(() => screen.getByText('+ Add Employee'));
      fireEvent.click(screen.getByText('+ Add Employee'));
    };

    const fillForm = (username, name, email) => {
      if (username) fireEvent.change(screen.getByPlaceholderText('e.g. jsmith'),        { target: { value: username } });
      if (name)     fireEvent.change(screen.getByPlaceholderText('e.g. John Smith'),    { target: { value: name } });
      if (email)    fireEvent.change(screen.getByPlaceholderText('e.g. john@example.com'), { target: { value: email } });
    };

    it('shows validation error when all fields are empty', async () => {
      render(<Employees />);
      await openModal();
      fireEvent.click(screen.getByText('Save'));
      expect(screen.getByText('All fields are required.')).toBeInTheDocument();
    });

    it('shows validation error when only some fields are filled', async () => {
      render(<Employees />);
      await openModal();
      fillForm('testuser', '', '');
      fireEvent.click(screen.getByText('Save'));
      expect(screen.getByText('All fields are required.')).toBeInTheDocument();
    });

    it('calls addDoc with trimmed values on valid input', async () => {
      addDoc.mockResolvedValue({ id: 'new-id' });
      getDocs
        .mockResolvedValueOnce(mockSnapshot(EMPLOYEES))
        .mockResolvedValueOnce(mockSnapshot([
          ...EMPLOYEES,
          { id: 'new-id', username: 'newuser', name: 'New User', email: 'new@example.com' },
        ]));
      render(<Employees />);
      await openModal();
      fillForm(' newuser ', ' New User ', ' new@example.com ');
      fireEvent.click(screen.getByText('Save'));
      await waitFor(() => {
        expect(addDoc).toHaveBeenCalledOnce();
        const payload = addDoc.mock.calls[0][1];
        expect(payload.username).toBe('newuser');
        expect(payload.name).toBe('New User');
        expect(payload.email).toBe('new@example.com');
      });
    });

    it('refreshes the employee list after a successful create', async () => {
      addDoc.mockResolvedValue({ id: 'new-id' });
      getDocs
        .mockResolvedValueOnce(mockSnapshot(EMPLOYEES))
        .mockResolvedValueOnce(mockSnapshot([
          ...EMPLOYEES,
          { id: 'new-id', username: 'newuser', name: 'New User', email: 'new@example.com' },
        ]));
      render(<Employees />);
      await openModal();
      fillForm('newuser', 'New User', 'new@example.com');
      fireEvent.click(screen.getByText('Save'));
      await waitFor(() =>
        expect(screen.getByText('4 team members')).toBeInTheDocument()
      );
    });

    it('shows an error message when addDoc throws', async () => {
      addDoc.mockRejectedValue(new Error('Write failed'));
      render(<Employees />);
      await openModal();
      fillForm('u', 'n', 'e@e.com');
      fireEvent.click(screen.getByText('Save'));
      await waitFor(() =>
        expect(screen.getByText('Failed to create employee.')).toBeInTheDocument()
      );
    });
  });

  // ── 3. toggleSelect ──────────────────────────────────────────────────────────
  describe('toggleSelect', () => {
    const enterSelectMode = async () => {
      await waitFor(() => screen.getByText('Delete'));
      fireEvent.click(screen.getByText('Delete'));
    };

    it('selects an employee when their checkbox is clicked', async () => {
      render(<Employees />);
      await enterSelectMode();
      const [, first] = screen.getAllByRole('checkbox');
      fireEvent.click(first);
      expect(first).toBeChecked();
    });

    it('deselects an employee when their checkbox is clicked again', async () => {
      render(<Employees />);
      await enterSelectMode();
      const [, first] = screen.getAllByRole('checkbox');
      fireEvent.click(first);
      expect(first).toBeChecked();
      fireEvent.click(first);
      expect(first).not.toBeChecked();
    });

    it('updates the selection count label as rows are toggled', async () => {
      render(<Employees />);
      await enterSelectMode();
      const [, first, second] = screen.getAllByRole('checkbox');
      fireEvent.click(first);
      expect(screen.getByText('1 selected')).toBeInTheDocument();
      fireEvent.click(second);
      expect(screen.getByText('2 selected')).toBeInTheDocument();
    });
  });

  // ── 4. toggleSelectAll ───────────────────────────────────────────────────────
  describe('toggleSelectAll', () => {
    const enterSelectMode = async () => {
      await waitFor(() => screen.getByText('Delete'));
      fireEvent.click(screen.getByText('Delete'));
    };

    it('selects all employees when none are selected', async () => {
      render(<Employees />);
      await enterSelectMode();
      const [selectAll] = screen.getAllByRole('checkbox');
      fireEvent.click(selectAll);
      expect(screen.getByText('3 selected')).toBeInTheDocument();
    });

    it('deselects all employees when all are already selected', async () => {
      render(<Employees />);
      await enterSelectMode();
      const [selectAll] = screen.getAllByRole('checkbox');
      fireEvent.click(selectAll);
      expect(screen.getByText('3 selected')).toBeInTheDocument();
      fireEvent.click(selectAll);
      expect(screen.getByText('0 selected')).toBeInTheDocument();
    });

    it('selects all when only a partial selection exists', async () => {
      render(<Employees />);
      await enterSelectMode();
      const [selectAll, first] = screen.getAllByRole('checkbox');
      fireEvent.click(first);
      expect(screen.getByText('1 selected')).toBeInTheDocument();
      fireEvent.click(selectAll);
      expect(screen.getByText('3 selected')).toBeInTheDocument();
    });
  });

  // ── 5. handleDeleteSelected ──────────────────────────────────────────────────
  describe('handleDeleteSelected', () => {
    const enterSelectMode = async () => {
      await waitFor(() => screen.getByText('Delete'));
      fireEvent.click(screen.getByText('Delete'));
    };

    beforeEach(() => {
      vi.spyOn(window, 'confirm').mockReturnValue(true);
      deleteDoc.mockResolvedValue();
    });

    it('calls deleteDoc once for each selected employee', async () => {
      render(<Employees />);
      await enterSelectMode();
      const [, first, second] = screen.getAllByRole('checkbox');
      fireEvent.click(first);
      fireEvent.click(second);
      fireEvent.click(screen.getByText('Delete Selected'));
      await waitFor(() => expect(deleteDoc).toHaveBeenCalledTimes(2));
    });

    it('removes deleted employees from the rendered list', async () => {
      render(<Employees />);
      await enterSelectMode();
      const [, first] = screen.getAllByRole('checkbox');
      fireEvent.click(first);
      fireEvent.click(screen.getByText('Delete Selected'));
      await waitFor(() =>
        expect(screen.queryByText('@jsmith')).not.toBeInTheDocument()
      );
    });

    it('does not delete when the user cancels the confirm dialog', async () => {
      window.confirm.mockReturnValue(false);
      render(<Employees />);
      await enterSelectMode();
      const [, first] = screen.getAllByRole('checkbox');
      fireEvent.click(first);
      fireEvent.click(screen.getByText('Delete Selected'));
      await waitFor(() => {
        expect(deleteDoc).not.toHaveBeenCalled();
        expect(screen.getByText('@jsmith')).toBeInTheDocument();
      });
    });

    it('shows an error message when deleteDoc throws', async () => {
      deleteDoc.mockRejectedValue(new Error('Delete failed'));
      render(<Employees />);
      await enterSelectMode();
      const [, first] = screen.getAllByRole('checkbox');
      fireEvent.click(first);
      fireEvent.click(screen.getByText('Delete Selected'));
      await waitFor(() =>
        expect(screen.getByText(/Failed to delete/)).toBeInTheDocument()
      );
    });
  });

  // ── 6. exitSelectMode ────────────────────────────────────────────────────────
  describe('exitSelectMode', () => {
    const enterSelectMode = async () => {
      await waitFor(() => screen.getByText('Delete'));
      fireEvent.click(screen.getByText('Delete'));
    };

    it('hides all checkboxes when Cancel is clicked', async () => {
      render(<Employees />);
      await enterSelectMode();
      expect(screen.getAllByRole('checkbox')).toHaveLength(4); // 1 select-all + 3 rows
      fireEvent.click(screen.getByText('Cancel'));
      expect(screen.queryByRole('checkbox')).not.toBeInTheDocument();
    });

    it('clears the selection so re-entering shows no checked rows', async () => {
      render(<Employees />);
      await enterSelectMode();
      const [, first] = screen.getAllByRole('checkbox');
      fireEvent.click(first);
      expect(screen.getByText('1 selected')).toBeInTheDocument();
      fireEvent.click(screen.getByText('Cancel'));
      fireEvent.click(screen.getByText('Delete')); // re-enter
      const [, firstAgain] = screen.getAllByRole('checkbox');
      expect(firstAgain).not.toBeChecked();
    });

    it('restores the Add Employee and Delete buttons after exiting', async () => {
      render(<Employees />);
      await enterSelectMode();
      fireEvent.click(screen.getByText('Cancel'));
      expect(screen.getByText('+ Add Employee')).toBeInTheDocument();
      expect(screen.getByText('Delete')).toBeInTheDocument();
    });
  });
});
