import { createMiddlewareClient } from "@supabase/auth-helpers-nextjs"
import { NextResponse } from "next/server"
import type { NextRequest } from "next/server"

export async function middleware(req: NextRequest) {
  const res = NextResponse.next()

  try {
    // Create a Supabase client configured to use cookies
    const supabase = createMiddlewareClient({ req, res })

    // Refresh session if expired - required for Server Components
    const {
      data: { session },
      error,
    } = await supabase.auth.getSession()

    // If there's an error getting the session, allow the request to continue
    // but redirect to login if trying to access protected routes
    if (error) {
      console.error("Middleware session error:", error)

      if (req.nextUrl.pathname.startsWith("/dashboard") || req.nextUrl.pathname.startsWith("/profile")) {
        const protocol = req.headers.get("x-forwarded-proto") || "https"
        const host = req.headers.get("host") || req.headers.get("x-forwarded-host") || ""
        const baseUrl = `${protocol}://${host}`

        const redirectUrl = new URL("/login", baseUrl)
        redirectUrl.searchParams.set("redirectedFrom", req.nextUrl.pathname)
        return NextResponse.redirect(redirectUrl)
      }

      return res
    }

    // Check auth condition
    if (!session && (req.nextUrl.pathname.startsWith("/dashboard") || req.nextUrl.pathname.startsWith("/profile"))) {
      // Auth required for these routes, redirect to login
      const protocol = req.headers.get("x-forwarded-proto") || "https"
      const host = req.headers.get("host") || req.headers.get("x-forwarded-host") || ""
      const baseUrl = `${protocol}://${host}`

      const redirectUrl = new URL("/login", baseUrl)
      redirectUrl.searchParams.set("redirectedFrom", req.nextUrl.pathname)
      return NextResponse.redirect(redirectUrl)
    }

    // If user is signed in and the current path is /login or /signup, redirect to /dashboard
    if (session && (req.nextUrl.pathname === "/login" || req.nextUrl.pathname === "/signup")) {
      const protocol = req.headers.get("x-forwarded-proto") || "https"
      const host = req.headers.get("host") || req.headers.get("x-forwarded-host") || ""
      const baseUrl = `${protocol}://${host}`

      const redirectUrl = new URL("/dashboard", baseUrl)
      return NextResponse.redirect(redirectUrl)
    }
  } catch (error) {
    console.error("Middleware auth error:", error)
    // If there's an error, allow the request to continue
    // This prevents auth errors from blocking the entire site
  }

  return res
}

export const config = {
  matcher: ["/dashboard/:path*", "/profile/:path*", "/login", "/signup"],
}

