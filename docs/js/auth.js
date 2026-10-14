/**
 * JWT Authentication Module for Lecturer Attendance Portal
 * Powered by Supabase Auth with JWT Token Management
 */

const SUPABASE_URL = 'https://loinljaeiqxknnfjaqfd.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_-E5fFgUO7vCf69oOJ5TUBg_74kmAKcT';
const JWT_STORAGE_KEY = 'lecturer_jwt_auth_session';

// Initialize Supabase Client
const supabase = window.supabase ? window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY) : null;

export class AuthService {
  static currentUser = null;
  static currentSession = null;
  static authListeners = [];

  /**
   * Initializes auth state from stored JWT session or active Supabase session
   */
  static async init() {
    // 1. Check local JWT storage
    const stored = localStorage.getItem(JWT_STORAGE_KEY);
    if (stored) {
      try {
        const sessionData = JSON.parse(stored);
        if (sessionData && sessionData.access_token) {
          // Check expiration
          const decoded = this.decodeJwt(sessionData.access_token);
          if (decoded && decoded.exp * 1000 > Date.now()) {
            this.currentSession = sessionData;
            this.currentUser = {
              id: decoded.sub || sessionData.user?.id || 'demo_user',
              email: decoded.email || sessionData.user?.email || 'lecturer@university.edu',
              name: sessionData.user?.user_metadata?.full_name || decoded.user_metadata?.full_name || 'Dr. Lecturer',
              role: decoded.role || 'authenticated',
              jwtDecoded: decoded,
              rawToken: sessionData.access_token
            };
          } else {
            // Expired
            localStorage.removeItem(JWT_STORAGE_KEY);
          }
        }
      } catch (e) {
        console.warn('Failed to parse cached JWT session', e);
        localStorage.removeItem(JWT_STORAGE_KEY);
      }
    }

    // 2. Sync with Supabase Auth state if online
    if (supabase) {
      try {
        const { data } = await supabase.auth.getSession();
        if (data && data.session) {
          this.setSession(data.session);
        }

        supabase.auth.onAuthStateChange((event, session) => {
          if (session) {
            this.setSession(session);
          } else if (event === 'SIGNED_OUT') {
            this.clearSession();
          }
        });
      } catch (e) {
        console.warn('Supabase getSession notice', e);
      }
    }

    this._notifyListeners();
    return this.currentUser;
  }

  static setSession(session) {
    if (!session || !session.access_token) return;
    this.currentSession = session;
    const decoded = this.decodeJwt(session.access_token);
    this.currentUser = {
      id: session.user?.id || decoded?.sub || 'usr_lecturer',
      email: session.user?.email || decoded?.email || 'lecturer@university.edu',
      name: session.user?.user_metadata?.full_name || decoded?.user_metadata?.full_name || 'Dr. Lecturer',
      role: decoded?.role || 'authenticated',
      jwtDecoded: decoded,
      rawToken: session.access_token
    };

    localStorage.setItem(JWT_STORAGE_KEY, JSON.stringify(session));
    this._notifyListeners();
  }

  static clearSession() {
    this.currentUser = null;
    this.currentSession = null;
    localStorage.removeItem(JWT_STORAGE_KEY);
    this._notifyListeners();
  }

  /**
   * Decodes a JWT token payload without external libraries
   */
  static decodeJwt(token) {
    try {
      const parts = token.split('.');
      if (parts.length !== 3) return null;
      const base64Url = parts[1];
      const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
      const jsonPayload = decodeURIComponent(
        atob(base64)
          .split('')
          .map(c => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
          .join('')
      );
      return JSON.parse(jsonPayload);
    } catch (e) {
      console.error('Invalid JWT format', e);
      return null;
    }
  }

  /**
   * Sign In with Email & Password
   */
  static async signIn(email, password) {
    if (!supabase) throw new Error('Supabase client not initialized');
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });
    if (error) throw error;
    this.setSession(data.session);
    return this.currentUser;
  }

  /**
   * Sign Up with Email & Password
   */
  static async signUp(email, password, fullName) {
    if (!supabase) throw new Error('Supabase client not initialized');
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          full_name: fullName,
        },
      },
    });
    if (error) throw error;
    if (data.session) {
      this.setSession(data.session);
    }
    return data;
  }

  /**
   * Quick Demo Login (Generates compliant JWT for instant test-drive)
   */
  static quickDemoLogin(lecturerName = 'Prof. Emeka Eze', email = 'emeka.eze@university.edu.ng') {
    const header = btoa(JSON.stringify({ alg: "HS256", typ: "JWT" }));
    const now = Math.floor(Date.now() / 1000);
    const exp = now + 86400 * 7; // 7 days
    const payload = btoa(JSON.stringify({
      sub: 'demo_lecturer_' + Math.random().toString(36).substring(2, 9),
      email: email,
      aud: 'authenticated',
      role: 'authenticated',
      user_metadata: { full_name: lecturerName },
      app_metadata: { provider: 'email' },
      iat: now,
      exp: exp
    }));
    const mockSig = btoa('verified_lecturer_signature_key');
    const mockJwt = `${header}.${payload}.${mockSig}`;

    const mockSession = {
      access_token: mockJwt,
      token_type: 'bearer',
      expires_in: 86400 * 7,
      expires_at: exp,
      user: {
        id: 'demo_lecturer_uid',
        email: email,
        user_metadata: { full_name: lecturerName }
      }
    };

    this.setSession(mockSession);
    return this.currentUser;
  }

  static async signOut() {
    if (supabase) {
      try {
        await supabase.auth.signOut();
      } catch (e) {
        console.warn('Signout warning', e);
      }
    }
    this.clearSession();
  }

  static onAuthStateChanged(cb) {
    this.authListeners.push(cb);
    cb(this.currentUser);
    return () => {
      this.authListeners = this.authListeners.filter(l => l !== cb);
    };
  }

  static _notifyListeners() {
    for (const listener of this.authListeners) {
      try {
        listener(this.currentUser);
      } catch (e) {
        console.error(e);
      }
    }
  }

  static getRawToken() {
    return this.currentSession?.access_token || null;
  }

  static isAuthenticated() {
    return !!this.currentUser && !!this.currentSession;
  }
}

export { supabase };
