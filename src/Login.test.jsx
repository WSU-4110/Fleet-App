import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import Login from "./Login";
import { signInWithEmailAndPassword } from "firebase/auth";
import { vi } from "vitest";
import "@testing-library/jest-dom";

const mockNavigate = vi.fn();

vi.mock("react-router-dom", () => ({
  useNavigate: () => mockNavigate,
}));

vi.mock("./firebase", () => ({
  auth: {},
}));

vi.mock("firebase/auth", async () => {
  const actual = await vi.importActual("firebase/auth");
  return {
    ...actual,
    signInWithEmailAndPassword: vi.fn(),
  };
});

describe("Login Component", () => {

  beforeEach(() => {
    vi.clearAllMocks();
  });


  test("renders email and password inputs", () => {
    render(<Login />);
    expect(screen.getByPlaceholderText("you@example.com")).toBeInTheDocument();
    expect(screen.getByPlaceholderText("••••••••")).toBeInTheDocument();
  });


  test("updates email and password fields", () => {
    render(<Login />);
    
    const emailInput = screen.getByPlaceholderText("you@example.com");
    const passwordInput = screen.getByPlaceholderText("••••••••");

    fireEvent.change(emailInput, { target: { value: "test@test.com" } });
    fireEvent.change(passwordInput, { target: { value: "123456" } });

    expect(emailInput.value).toBe("test@test.com");
    expect(passwordInput.value).toBe("123456");
  });


  test("calls firebase and shows success message", async () => {
    signInWithEmailAndPassword.mockResolvedValueOnce({});

    render(<Login />);

    fireEvent.change(screen.getByPlaceholderText("you@example.com"), {
      target: { value: "test@test.com" },
    });

    fireEvent.change(screen.getByPlaceholderText("••••••••"), {
      target: { value: "123456" },
    });

    fireEvent.click(screen.getByText("Sign in"));

    await waitFor(() => {
      expect(signInWithEmailAndPassword).toHaveBeenCalled();
    });

    expect(screen.getByText("✅ Login successful")).toBeInTheDocument();
  });


  test("shows error message on failed login", async () => {
    signInWithEmailAndPassword.mockRejectedValueOnce(new Error());

    render(<Login />);

    fireEvent.change(screen.getByPlaceholderText("you@example.com"), {
      target: { value: "wrong@test.com" },
    });

    fireEvent.change(screen.getByPlaceholderText("••••••••"), {
      target: { value: "wrongpass" },
    });

    fireEvent.click(screen.getByText("Sign in"));

    await waitFor(() => {
      expect(screen.getByText("⚠️ Invalid email or password.")).toBeInTheDocument();
    });
  });


test("shows loading text while logging in", async () => {
  signInWithEmailAndPassword.mockImplementation(
    () => new Promise(() => {}) 
  );

  render(<Login />);

  fireEvent.change(screen.getByPlaceholderText("you@example.com"), {
    target: { value: "test@test.com" },
  });

  fireEvent.change(screen.getByPlaceholderText("••••••••"), {
    target: { value: "123456" },
  });
  fireEvent.click(screen.getByText("Sign in"));

  await waitFor(() => {
    expect(screen.getByText("Signing in...")).toBeInTheDocument();
  });
});

test("navigates to forgot password page when link is clicked", () => {
  render(<Login />);

 
  fireEvent.click(screen.getByText("Forgot password?"));

  
  expect(mockNavigate).toHaveBeenCalledWith("/forgot-password");
});

});