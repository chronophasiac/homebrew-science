require "formula"

class GmshSvnStrategy < SubversionDownloadStrategy
  def quiet_safe_system *args
    super *args + ["--username", "getdp", "--password", "getdp"]
  end
end

class Getdp < Formula
  homepage "http://www.geuz.org/getdp/"
  url "http://www.geuz.org/getdp/src/getdp-2.4.3-source.tgz"
  sha1 "905a82c37e36be17ed9f825c26df095a79af3250"

  head 'https://geuz.org/svn/getdp/trunk', :using => GmshSvnStrategy

  option "without-check", "skip build-time tests (not recommended)"

  depends_on :fortran
  depends_on :mpi => [:cc, :cxx, :f90, :recommended]
  depends_on "arpack" => :recommended
  depends_on "petsc" => :recommended
  depends_on "slepc" => :recommended
  depends_on "gmsh" => :recommended
  depends_on "gsl" => :recommended
  depends_on "cmake" => :build

  def install
    args = std_cmake_args
    args << "-DENABLE_BUILD_SHARED=ON"
    args << "-DENABLE_ARPACK=OFF" if build.without? "arpack"
    args << "-DENABLE_GMSH=OFF"   if build.without? "gmsh"
    args << "-DENABLE_GSL=OFF"    if build.without? "gsl"

    if build.with? "petsc"
      ENV["PETSC_DIR"] = Formula["petsc"].prefix
      ENV["PETSC_ARCH"] = "arch-darwin-c-opt"
    else
      args << "-DENABLE_PETSC=OFF"
    end

    if build.with? "slepc"
      ENV["SLEPC_DIR"] = Formula["slepc"].prefix
    else
      args << "-DENABLE_SLEPC=OFF"
    end

    if (build.with? "petsc") or (build.with? "slepc")
      args << "-DENABLE_MPI=ON" if build.with? :mpi
    end

    # Fixed test to work without access to gmsh
    inreplace "CMakeLists.txt", "../../gmsh/bin/gmsh", "./getdp"

    # Fix GMSH library final destination
    inreplace "CMakeLists.txt", "DESTINATION ${GMSH_LIB}", "DESTINATION #{lib}"

    mkdir "build" do
      system "cmake", "..", *args
      system "make"
      system "make", "install"
      system "make", "test" if build.with? "check"
    end
  end

end
