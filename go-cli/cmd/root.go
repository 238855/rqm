// RQM - Requirements Management in Code
// Copyright (c) 2025
// SPDX-License-Identifier: MIT

package cmd

import (
    "fmt"
    "os"

    "github.com/spf13/cobra"
    "github.com/spf13/viper"
)

var cfgFile string

// rootCmd represents the base command when called without any subcommands
var rootCmd = &cobra.Command{
    Use:   "rqm",
    Short: "Requirements Management in Code",
    Long: `RQM (also usable as 'requim') is a requirements management tool 
that allows you to manage requirements as code using structured YAML files.

It provides powerful features for:
  - Defining requirements with full traceability
  - Building requirement trees with circular reference detection
  - Validating requirements against a JSON schema
  - Querying and visualizing requirement relationships`,
    Version: "0.1.0",
}

// Execute adds all child commands to the root command and sets flags appropriately.
func Execute() {
    err := rootCmd.Execute()
    if err != nil {
        os.Exit(1)
    }
}

func init() {
    cobra.OnInitialize(initConfig)

    rootCmd.PersistentFlags().StringVar(&cfgFile, "config", "", "config file (default is $HOME/.rqm.yaml)")
    rootCmd.PersistentFlags().BoolP("verbose", "v", false, "verbose output")
}

// initConfig reads in config file and ENV variables if set.
func initConfig() {
    if cfgFile != "" {
        viper.SetConfigFile(cfgFile)
    } else {
        home, err := os.UserHomeDir()
        cobra.CheckErr(err)

        viper.AddConfigPath(home)
        viper.SetConfigType("yaml")
        viper.SetConfigName(".rqm")
    }

    viper.AutomaticEnv()

    if err := viper.ReadInConfig(); err == nil {
        if viper.GetBool("verbose") {
            fmt.Fprintln(os.Stderr, "Using config file:", viper.ConfigFileUsed())
        }
    }
}
