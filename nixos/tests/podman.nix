# This test runs podman and checks if simple container starts

import ./make-test-python.nix (
  { pkgs, lib, ... }: {
    name = "podman";
    meta = {
      maintainers = lib.teams.podman.members;
    };

    nodes = {
      podman =
        { pkgs, ... }:
        {
          virtualisation.podman.enable = true;

          users.users.alice = {
            isNormalUser = true;
            home = "/home/alice";
            description = "Alice Foobar";
          };

        };
    };

    testScript = ''
      import shlex


      def su_cmd(cmd):
          cmd = shlex.quote(cmd)
          return f"su alice -l -c {cmd}"


      podman.wait_for_unit("sockets.target")
      start_all()

      with subtest("Run container as root with runc"):
          podman.succeed("tar cv --files-from /dev/null | podman import - scratchimg")
          podman.succeed(
              "podman run --runtime=runc -d --name=sleeping -v /nix/store:/nix/store -v /run/current-system/sw/bin:/bin scratchimg /bin/sleep 10"
          )
          podman.succeed("podman ps | grep sleeping")
          podman.succeed("podman stop sleeping")
          podman.succeed("podman rm sleeping")

      with subtest("Run container as root with crun"):
          podman.succeed("tar cv --files-from /dev/null | podman import - scratchimg")
          podman.succeed(
              "podman run --runtime=crun -d --name=sleeping -v /nix/store:/nix/store -v /run/current-system/sw/bin:/bin scratchimg /bin/sleep 10"
          )
          podman.succeed("podman ps | grep sleeping")
          podman.succeed("podman stop sleeping")
          podman.succeed("podman rm sleeping")

      with subtest("Run container as root with the default backend"):
          podman.succeed("tar cv --files-from /dev/null | podman import - scratchimg")
          podman.succeed(
              "podman run -d --name=sleeping -v /nix/store:/nix/store -v /run/current-system/sw/bin:/bin scratchimg /bin/sleep 10"
          )
          podman.succeed("podman ps | grep sleeping")
          podman.succeed("podman stop sleeping")
          podman.succeed("podman rm sleeping")


      podman.succeed(
          "mkdir -p /tmp/podman-run-1000/libpod && chown alice -R /tmp/podman-run-1000"
      )


      with subtest("Run container rootless with crun"):
          podman.succeed(su_cmd("tar cv --files-from /dev/null | podman import - scratchimg"))
          podman.succeed(
              su_cmd(
                  "podman run --runtime=crun -d --name=sleeping -v /nix/store:/nix/store -v /run/current-system/sw/bin:/bin scratchimg /bin/sleep 10"
              )
          )
          podman.succeed(su_cmd("podman ps | grep sleeping"))
          podman.succeed(su_cmd("podman stop sleeping"))
          podman.succeed(su_cmd("podman rm sleeping"))
      # As of 2020-11-20, the runc backend doesn't work with cgroupsv2 yet, so we don't run that test.

      with subtest("Run container rootless with the default backend"):
          podman.succeed(su_cmd("tar cv --files-from /dev/null | podman import - scratchimg"))
          podman.succeed(
              su_cmd(
                  "podman run -d --name=sleeping -v /nix/store:/nix/store -v /run/current-system/sw/bin:/bin scratchimg /bin/sleep 10"
              )
          )
          podman.succeed(su_cmd("podman ps | grep sleeping"))
          podman.succeed(su_cmd("podman stop sleeping"))
          podman.succeed(su_cmd("podman rm sleeping"))
    '';
  }
)
