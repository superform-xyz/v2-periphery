// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import "forge-std/console2.sol";
import "forge-std/StdJson.sol";
import "forge-std/Script.sol";

/// @title CoreS3Fetcher
/// @notice Utility to fetch core contract addresses from S3 bucket using AWS CLI
abstract contract CoreS3Fetcher is Script {
    using stdJson for string;

    /*//////////////////////////////////////////////////////////////
                            CONSTANTS
    //////////////////////////////////////////////////////////////*/
    string constant CORE_S3_BUCKET = "vnet-state";

    /*//////////////////////////////////////////////////////////////
                            ERRORS
    //////////////////////////////////////////////////////////////*/
    error CoreS3Fetcher__FetchFailed(uint256 status, string url);
    error CoreS3Fetcher__InvalidJson(string data);
    error CoreS3Fetcher__WriteFileFailed(string path);

    /*//////////////////////////////////////////////////////////////
                            FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Fetches core contract addresses from S3 and saves to local file
    /// @param branchName The branch name to fetch from (e.g., "main", "dev", "local")
    /// @return coreJson The JSON string containing core contract addresses
    function fetchAndSaveCoreContracts(string memory branchName) internal returns (string memory coreJson) {
        console2.log("Fetching core contracts from S3 for branch:", branchName);

        // Construct S3 path
        string memory s3Path = string.concat("s3://", CORE_S3_BUCKET, "/", branchName, "/latest.json");
        string memory tempFile = "script/core-output/temp_download.json";

        console2.log("S3 Path:", s3Path);

        // Use AWS CLI to fetch from S3 (handles authentication)
        string[] memory awsCmd = new string[](5);
        awsCmd[0] = "aws";
        awsCmd[1] = "s3";
        awsCmd[2] = "cp";
        awsCmd[3] = s3Path;
        awsCmd[4] = tempFile;

        try vm.ffi(awsCmd) {
            console2.log("Successfully downloaded from S3");
        } catch {
            revert CoreS3Fetcher__FetchFailed(404, s3Path);
        }

        // Read the downloaded file
        try vm.readFile(tempFile) returns (string memory content) {
            coreJson = content;
        } catch {
            revert CoreS3Fetcher__FetchFailed(500, "Failed to read downloaded file");
        }

        // Validate JSON
        if (!_isValidJson(coreJson)) {
            revert CoreS3Fetcher__InvalidJson(coreJson);
        }

        console2.log("Successfully fetched core contracts JSON from S3");

        // Clean up temp file
        string[] memory rmCmd = new string[](2);
        rmCmd[0] = "rm";
        rmCmd[1] = tempFile;
        try vm.ffi(rmCmd) { } catch { }

        // Save to local file
        _saveCoreContractsToFile(branchName, coreJson);

        return coreJson;
    }

    /// @notice Reads core contracts from local file if it exists
    /// @param branchName The branch name
    /// @return coreJson The JSON string, empty if file doesn't exist
    function readCoreContractsFromFile(string memory branchName) internal view returns (string memory coreJson) {
        string memory filePath = _getCoreOutputPath(branchName);

        try vm.readFile(filePath) returns (string memory content) {
            return content;
        } catch {
            console2.log("Core contracts file not found at:", filePath);
            return "";
        }
    }

    /// @notice Gets a contract address from the core JSON by network and contract name
    /// @param coreJson The core contracts JSON string
    /// @param networkName The network name (e.g., "Ethereum", "Base", "Optimism")
    /// @param contractName The contract name (e.g., "SuperDeployer", "ApproveERC20Hook")
    /// @return contractAddress The contract address
    function getContractAddress(
        string memory coreJson,
        string memory networkName,
        string memory contractName
    )
        internal
        pure
        returns (address contractAddress)
    {
        string memory key = string.concat(".networks.", networkName, ".contracts.", contractName);

        return coreJson.readAddress(key);
    }

    /*//////////////////////////////////////////////////////////////
                            PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Saves core contracts JSON to local file
    /// @param branchName The branch name
    /// @param coreJson The JSON content to save
    function _saveCoreContractsToFile(string memory branchName, string memory coreJson) private {
        string memory outputDir = string.concat("script/core-output/", branchName);
        string memory filePath = _getCoreOutputPath(branchName);

        // Create directory structure
        vm.createDir(outputDir, true);

        // Write file
        try vm.writeFile(filePath, coreJson) {
            console2.log("Successfully saved core contracts to:", filePath);
        } catch {
            revert CoreS3Fetcher__WriteFileFailed(filePath);
        }
    }

    /// @notice Gets the full path for core output file
    /// @param branchName The branch name
    /// @return filePath The full file path
    function _getCoreOutputPath(string memory branchName) private pure returns (string memory) {
        return string.concat("script/core-output/", branchName, "/latest.json");
    }

    /// @notice Validates if a string is valid JSON
    /// @param jsonStr The JSON string to validate
    /// @return isValid True if valid JSON
    function _isValidJson(string memory jsonStr) private pure returns (bool isValid) {
        try vm.parseJson(jsonStr) {
            return true;
        } catch {
            return false;
        }
    }
}
