#include <iostream>
#include <vector>
#include <string>
#include "rapidjson/document.h"
#include "rapidjson/stringbuffer.h"
#include "curl.h" // ToolsCURL
#include "package.h" // ToolsPackage

// Definitions for this source file
#include "repo.h"

// Fetches and parses repository JSON from the given URL
std::vector<const ToolsPackage::PackageData*> ToolsRepo::fetchRepository (const std::string &url) {

  std::string jsonString = ToolsCURL::downloadString(url);

  // Parse the repository index
  rapidjson::Document doc;
  doc.Parse(jsonString.c_str());

  // Count the packages in the repository
  rapidjson::Value &packages = doc["packages"];
  const int packageCount = packages.Size();

  // Create a vector, since a dynamic array is a bit more of a pain in the ass
  std::vector<const ToolsPackage::PackageData*> repository;
  for (int i = 0; i < packageCount; i ++) {
    repository.push_back(new ToolsPackage::PackageData(packages[i]));
  }

  return repository;

}
