# NOTE: The cuda build is broken
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { nixpkgs, flake-utils, ... }: flake-utils.lib.eachDefaultSystem (system:
    let
      overlays = [
        (self: super: {
          mesa = super.mesa.override { enableOpenCL = true; };
          opencv4 = super.opencv4.override { enableFfmpeg = true; enableCuda = true; enableUnfree = true; };
        })
      ];
      pkgs = import nixpkgs {
        inherit system overlays;
        config.allowUnfree = true;
      };
      jt-flow = (with pkgs; stdenv.mkDerivation {
        pname = "JTFlow";
        version = "0.0.1";
        src = fetchgit {
          url = "https://github.com/michael-mueller-git/jt-flow.git";
          rev = "84f899066b95a0fd4dd0aab17067eca38c009305";
          sha256 = "sha256-jd08B0dewhbtQjkJwRfy+xKLuhRyqQNPBHfcXKtCT24=";
          fetchSubmodules = true;
        };
        nativeBuildInputs = [
          clang
          wget
          ffmpeg
          ninja
          opencl-headers
          opencl-clhpp
          opencl-clang
          ocl-icd
          cudaPackages.cudatoolkit
          cudaPackages.cudnn
          python310
          libGL
          python310Packages.numpy
          clang-ocl
          nv-codec-headers-11
          opencv
          mesa
          pkg-config
        ];
        configurePhase = ''
          echo "include_directories(${pkgs.nv-codec-headers-11}/include/ffnvcodec)" >> FlowLib/CMakeLists.txt
        '';
        buildPhase = "${pkgs.cmake}/bin/cmake FlowLib -DNIX=ON -DCUDA_CUDART_LIBRARY=${pkgs.cudaPackages.cudatoolkit}/lib -DOpenCL_INCLUDE_DIR=${pkgs.opencl-headers}/include -DOpenCL_LIBRARY=${pkgs.ocl-icd}/lib/libOpenCL.so -DCMAKE_CXX_STANDARD_REQUIRED=ON -DCMAKE_CXX_STANDARD=17 -DOpenCV_DIR=${pkgs.opencv}/lib/cmake/opencv4 -DPython3_NumPy_INCLUDE_DIRS=${pkgs.python310Packages.numpy} -DCMAKE_CUDA_ARCHITECTURES=75 && make -j $NIX_BUILD_CORES JTFlowLav && make -j $NIX_BUILD_CORES JTFlowUtilLav";
        installPhase = ''
          mkdir -p $out/bin
          mkdir -p $out/lib
          ls
          mv -fv libJTFlowLav.so $out/lib
          mv -fv JTFlowUtilLav $out/bin/JTFlow
        '';
      }
      );
    in
    rec {
      formatter = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
      defaultApp = flake-utils.lib.mkApp {
        drv = defaultPackage;
      };
      defaultPackage = jt-flow;
      devShell = pkgs.mkShell {
        buildInputs = [
          jt-flow
          pkgs.opencv
        ];
      };
    }
  );
}
