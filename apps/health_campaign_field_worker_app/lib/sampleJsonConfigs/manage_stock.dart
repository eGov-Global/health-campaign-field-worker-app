final dynamic sampleInventoryFlows = {
  "name": "INVENTORY",
  "initialPage": "manageStock",
  "project": "CMP-2026-03-17-000196",
  "version": 1,
  "disabled": false,
  "isSelected": true,
  "flows": [
    {
      "body": [
        {
          "type": "template",
          "label": "INVENTORY_STOCK_ACCEPT_SUCCESS_HEADING",
          "format": "panelCard",
          "heading": "INVENTORY_STOCK_ACCEPT_SUCCESS_HEADING",
          "fieldName": "stockAcknowledgement",
          "mandatory": true,
          "properties": {"type": "success"},
          "description": "INVENTORY_STOCK_ACCEPT_SUCCESS_DESCRIPTION",
          "primaryAction": {
            "type": "template",
            "label": "INVENTORY_STOCK_ACCEPT_SUCCESS_GO_BACK_BUTTON",
            "format": "button",
            "hidden": false,
            "onAction": [
              {
                "actionType": "NAVIGATION",
                "properties": {
                  "name": "manageStock",
                  "type": "TEMPLATE",
                  "navigationMode": "popAndPush"
                }
              }
            ],
            "fieldName": "GoToManageStock",
            "mandatory": true,
            "properties": {"type": "primary"}
          },
          "primaryActionLabel": "INVENTORY_STOCK_ACCEPT_SUCCESS_GO_BACK_BUTTON"
        }
      ],
      "name": "stock-acknowledgement",
      "order": 11,
      "footer": [],
      "header": [],
      "navigateTo": null,
      "screenType": "TEMPLATE",
      "initActions": [],
      "submitCondition": null,
      "preventScreenCapture": false
    },
    {
      "body": [
        {
          "label": "INVENTORY_NO_INCOMING_TRANSACTIONS_LABEL",
          "format": "infoCard",
          "hidden": "{{fn:hasResults('StockModel')}} == true",
          "schemaCode": null,
          "description": "INVENTORY_NO_INCOMING_TRANSACTIONS_DESCRIPTION"
        },
        {
          "child": {
            "format": "card",
            "children": [
              {
                "format": "row",
                "children": [
                  {
                    "type": "",
                    "label": "MRN {{item.groupKey}}",
                    "format": "tag"
                  },
                  {
                    "value":
                        "{{fn:formatDate(item.items[0].dateOfEntry, 'date', dd MMM yyyy)}}",
                    "format": "textTemplate"
                  }
                ],
                "properties": {
                  "mainAxisSize": "max",
                  "mainAxisAlignment": "spaceBetween"
                }
              },
              {
                "format": "row",
                "children": [
                  {
                    "format": "column",
                    "children": [
                      {
                        "value": "APP_CONFIG_INVENTORY_SENDER_LABEL",
                        "format": "textTemplate"
                      },
                      {
                        "value":
                            "{{fn:getFacilityName(item.items[0].senderId)}}",
                        "format": "textTemplate"
                      }
                    ],
                    "properties": {
                      "mainAxisSize": "min",
                      "mainAxisAlignment": "spaceBetween"
                    }
                  },
                  {
                    "value": "{{item.items[0].transactionType}}",
                    "format": "textTemplate"
                  }
                ],
                "properties": {
                  "mainAxisSize": "max",
                  "mainAxisAlignment": "spaceBetween"
                }
              },
              {
                "child": {
                  "value":
                      "{{item.additionalFields.fields.sku}}: {{item.quantity}}",
                  "format": "textTemplate"
                },
                "format": "listView",
                "fieldName": "groupedItems",
                "dataSource": "item.items"
              },
              {
                "label": "INVENTORY_SELECT_LABEL",
                "format": "button",
                "visible": "{{item.items[0].transactionType == 'DISPATCHED'}}",
                "onAction": [
                  {
                    "actionType": "NAVIGATION",
                    "properties": {
                      "data": [
                        {"key": "stockEntryType", "value": "RECEIPT"},
                        {"key": "transactionType", "value": "RECEIVED"},
                        {"key": "primaryRole", "value": "RECEIVER"},
                        {"key": "secondaryRole", "value": "SENDER"},
                        {
                          "key": "mrnNumber",
                          "value":
                              "{{item.items[0].additionalFields.fields.mrnNumber}}"
                        },
                        {"key": "isEdit", "value": "true"},
                        {"key": "prefillFromScan", "value": "true"},
                        {
                          "key": "senderFacilityId",
                          "value": "{{item.items[0].senderId}}"
                        },
                        {
                          "key": "quantity",
                          "value": "{{item.items[0].quantity}}"
                        },
                        {
                          "key": "wayBillNumber",
                          "value": "{{item.items[0].wayBillNumber}}"
                        },
                        {
                          "key": "productVariantId",
                          "value": "{{item.items[0].productVariantId}}"
                        },
                        {
                          "key": "sku",
                          "value":
                              "{{item.items[0].additionalFields.fields.sku}}"
                        },
                        {
                          "key": "batchNumber",
                          "value":
                              "{{item.items[0].additionalFields.fields.batchNumber}}"
                        },
                        {
                          "key": "comment",
                          "value":
                              "{{item.items[0].additionalFields.fields.comments}}"
                        },
                        {
                          "key": "clientReferenceId",
                          "value": "{{item.items[0].clientReferenceId}}"
                        }
                      ],
                      "name": "stockReceiptDetails",
                      "type": "FORM"
                    }
                  }
                ],
                "properties": {
                  "size": "medium",
                  "type": "primary",
                  "mainAxisSize": "max",
                  "mainAxisAlignment": "center"
                }
              }
            ]
          },
          "format": "listView",
          "hidden": "{{fn:hasResults('StockModel')}} == false",
          "fieldName": "incomingList",
          "dataSource": "StockModel",
          "properties": {"spacing": "spacer4"},
          "schemaCode": null
        }
      ],
      "name": "incomingTransactions",
      "order": 9,
      "footer": [
        {
          "label": "INVENTORY_SCAN_STOCK_RECEIPT_HEADING",
          "format": "button",
          "visible":
              "{{fn:hasRole('COMMUNITY_DISTRIBUTOR')}} == true || {{fn:hasRole('DISTRIBUTOR')}} == true",
          "onAction": [
            {
              "actionType": "OPEN_SCANNER",
              "properties": {
                "onError": [
                  {
                    "actionType": "SHOW_TOAST",
                    "properties": {
                      "type": "error",
                      "message": "INVENTORY_SCAN_INVALID_QR"
                    }
                  }
                ],
                "quantity": 1,
                "scanType": "qr",
                "fieldName": "scannedQrPayload",
                "isGS1code": false,
                "onSuccess": [
                  {
                    "actionType": "NAVIGATION",
                    "properties": {
                      "data": [
                        {
                          "key": "clientReferenceId",
                          "value": "{{clientReferenceId}}"
                        },
                        {"key": "senderId", "value": "{{senderId}}"},
                        {"key": "receiverId", "value": "{{receiverId}}"},
                        {"key": "boundaryCode", "value": "{{boundaryCode}}"},
                        {
                          "key": "productVariantId",
                          "value": "{{productVariantId}}"
                        },
                        {"key": "quantity", "value": "{{quantity}}"},
                        {"key": "waybillNumber", "value": "{{waybillNumber}}"},
                        {"key": "sku", "value": "{{sku}}"},
                        {"key": "batchNumber", "value": "{{batchNumber}}"},
                        {"key": "expiryDate", "value": "{{expiryDate}}"},
                        {"key": "comments", "value": "{{comments}}"}
                      ],
                      "name": "stockScanConfirm",
                      "type": "TEMPLATE"
                    }
                  }
                ],
                "parseJson": true,
                "singleValue": true
              }
            }
          ],
          "prefixIcon": "QrCodeScanner",
          "properties": {
            "size": "large",
            "type": "primary",
            "mainAxisSize": "max",
            "mainAxisAlignment": "center"
          }
        }
      ],
      "header": [
        {
          "label": "CORE_COMMON_BACK",
          "format": "backLink",
          "onAction": [
            {"actionType": "BACK_NAVIGATION", "properties": {}}
          ]
        }
      ],
      "heading": "INVENTORY_INCOMING_TRANSACTIONS_HEADING",
      "navigateTo": null,
      "screenType": "TEMPLATE",
      "description": "INVENTORY_INCOMING_TRANSACTIONS_DESCRIPTION",
      "initActions": [
        {
          "actionType": "SEARCH_EVENT",
          "properties": {
            "data": [
              {
                "key": "receiverId",
                "value": "{{fn:getUserFacilityId()}}",
                "operation": "equals"
              },
              {
                "key": "productVariantId",
                "value": "{{fn:getProjectProductVariantIds()}}",
                "operation": "in"
              }
            ],
            "name": "stock",
            "type": "SEARCH_EVENT",
            "awaitResults": true
          }
        }
      ],
      "wrapperConfig": {
        "filters": [
          {"field": "transactionType", "equals": "DISPATCHED"},
          {"field": "additionalFields.fields.status", "equals": "IN_TRANSIT"},
          {
            "join": {
              "sourceField":
                  "additionalFields.fields.dispatchClientReferenceId",
              "targetField": "clientReferenceId"
            },
            "entity": "StockModel",
            "condition": {"field": "transactionType", "equals": "RECEIVED"},
            "notExists": true
          }
        ],
        "groupBy": "additionalFields.fields.mrnNumber",
        "relations": [
          {"name": "stock", "entity": "StockModel"}
        ],
        "rootEntity": "StockModel",
        "groupByType": true,
        "wrapperName": "IncomingStockWrapper",
        "searchConfig": {
          "select": ["stock"],
          "orderBy": {"field": "clientCreatedTime", "order": "DESC"},
          "primary": "stock"
        }
      },
      "submitCondition": null,
      "preventScreenCapture": false
    },
    {
      "body": [
        {
          "child": {
            "format": "card",
            "children": [
              {
                "data": [
                  {
                    "key": "INVENTORY_RESOURCE_LABEL",
                    "value": "{{item.additionalFields.fields.sku}}"
                  },
                  {
                    "key": "INVENTORY_TRANSACTION_TYPE_LABEL",
                    "value": "{{item.transactionType}}"
                  },
                  {
                    "key": "INVENTORY_TRANSACTION_REASON_LABEL",
                    "value": "{{item.transactionReason}}"
                  },
                  {
                    "key": "APPONE_MANAGESTOCK_WAREHOUSE_label_dateOfReceipt",
                    "value":
                        "{{fn:formatDate(item.dateOfEntry, 'datetime', 'dd MMM yyyy HH:mm')}}"
                  },
                  {
                    "key":
                        "{{fn:getSecondPagePartyLabel(item.additionalFields.fields)}}",
                    "value":
                        "{{fn:getSecondPageParty(item.additionalFields.fields, item.senderId, item.receiverId)}}"
                  },
                  {
                    "key": "INVENTORY_MRN_NUMBER_LABEL",
                    "value": "{{item.additionalFields.fields.mrnNumber}}"
                  },
                  {
                    "key": "INVENTORY_WAYBILL_NUMBER_LABEL",
                    "value": "{{item.waybillNumber}}"
                  },
                  {
                    "key": "INVENTORY_BATCH_NUMBER_LABEL",
                    "value": "{{item.additionalFields.fields.batchNumber}}"
                  },
                  {
                    "key":
                        "{{fn:getQuantityLabel(item.additionalFields.fields.sku)}}",
                    "value": "{{item.quantity}}"
                  },
                  {
                    "key": "INVENTORY_COMMENTS_LABEL",
                    "value": "{{item.additionalFields.fields.comments}}"
                  }
                ],
                "format": "labelPairList"
              }
            ]
          },
          "format": "listView",
          "fieldName": "stockItems",
          "dataSource": "StockModel",
          "properties": {"spacing": "spacer4"},
          "schemaCode": null
        }
      ],
      "name": "viewTransactionDetails",
      "order": 8,
      "footer": [],
      "header": [
        {
          "label": "CORE_COMMON_BACK",
          "format": "backLink",
          "onAction": [
            {
              "actionType": "NAVIGATION",
              "properties": {"name": "manageStock", "type": "TEMPLATE"}
            }
          ]
        }
      ],
      "heading": "INVENTORY_STOCK_RECEIPT_DETAILS_HEADING",
      "navigateTo": null,
      "screenType": "TEMPLATE",
      "initActions": [
        {
          "actionType": "SEARCH_EVENT",
          "properties": {
            "data": [
              {
                "key": "additionalFields",
                "value": "{{navigation.selectedStock}}",
                "operation": "matches"
              }
            ],
            "name": "stock",
            "type": "SEARCH_EVENT"
          }
        }
      ],
      "wrapperConfig": {
        "filters": [],
        "relations": [
          {"name": "stock", "entity": "StockModel"}
        ],
        "rootEntity": "StockModel",
        "groupByType": true,
        "wrapperName": "ViewStockDetailsWrapper",
        "searchConfig": {
          "select": ["stock"],
          "primary": "stock"
        }
      },
      "submitCondition": null,
      "preventScreenCapture": false
    },
    {
      "body": [
        {
          "label": "INVENTORY_NO_TRANSACTIONS_LABEL",
          "format": "infoCard",
          "hidden": "{{fn:hasResults('StockModel')}} == true",
          "schemaCode": null,
          "description": "INVENTORY_NO_TRANSACTIONS_DESCRIPTION"
        },
        {
          "child": {
            "format": "card",
            "children": [
              {
                "format": "row",
                "children": [
                  {
                    "type": "template",
                    "label": "MRN {{item.groupKey}}",
                    "format": "tag",
                    "fieldName": "mrnTag"
                  },
                  {
                    "value":
                        "{{fn:formatDate(item.items[0].dateOfEntry, 'date', dd MMM yyyy)}}",
                    "format": "textTemplate"
                  }
                ],
                "properties": {
                  "mainAxisSize": "max",
                  "mainAxisAlignment": "spaceBetween"
                }
              },
              {
                "format": "row",
                "children": [
                  {
                    "format": "column",
                    "children": [
                      {
                        "value":
                            "{{fn:getFirstPagePartyLabel(item.items[0].additionalFields.fields)}}",
                        "format": "textTemplate"
                      },
                      {
                        "value":
                            "{{fn:getFirstPageParty(item.items[0].additionalFields.fields, item.items[0].senderId, item.items[0].receiverId)}}",
                        "format": "textTemplate"
                      }
                    ],
                    "properties": {
                      "mainAxisSize": "min",
                      "mainAxisAlignment": "spaceBetween"
                    }
                  },
                  {
                    "label": "INVENTORY_VIEW_QR_LABEL",
                    "format": "actionPopup",
                    "visible":
                        "{{item.items[0].transactionType}} == DISPATCHED",
                    "properties": {
                      "size": "medium",
                      "type": "tertiary",
                      "popupConfig": {
                        "body": [
                          {
                            "data": "{{fn:stockToScanQr(item.items[0])}}",
                            "size": "medium",
                            "format": "qr_view",
                            "padding": 16,
                            "backgroundColor": "white",
                            "dataModuleColor": "black",
                            "errorCorrectionLevel": "M"
                          }
                        ],
                        "type": "default",
                        "title": "INVENTORY_QR_CODE_TITLE",
                        "titleIcon": "qr",
                        "footerActions": [],
                        "showCloseButton": true,
                        "barrierDismissible": true
                      },
                      "mainAxisSize": "min",
                      "mainAxisAlignment": "start"
                    },
                    "suffixIcon": "qr"
                  }
                ],
                "properties": {
                  "mainAxisSize": "max",
                  "mainAxisAlignment": "spaceBetween"
                }
              },
              {
                "child": {
                  "value":
                      "{{item.additionalFields.fields.sku}}: {{item.quantity}}",
                  "format": "textTemplate"
                },
                "format": "listView",
                "fieldName": "groupedItems",
                "dataSource": "item.items"
              },
              {
                "label": "INVENTORY_SELECT_TRANSACTION_LABEL",
                "format": "button",
                "onAction": [
                  {
                    "actionType": "NAVIGATION",
                    "properties": {
                      "data": [
                        {"key": "selectedStock", "value": "{{item.groupKey}}"},
                        {
                          "key": "clientReferenceId",
                          "value": "{{item.items[0].clientReferenceId}}"
                        }
                      ],
                      "name": "viewTransactionDetails",
                      "type": "TEMPLATE",
                      "navigationMode": "popUntilAndPush",
                      "popUntilPageName": "manageStock"
                    }
                  }
                ],
                "properties": {
                  "size": "medium",
                  "type": "primary",
                  "mainAxisSize": "max",
                  "mainAxisAlignment": "center"
                }
              }
            ]
          },
          "format": "listView",
          "hidden": "{{ context.stock.isEmpty }}",
          "fieldName": "listView",
          "dataSource": "StockModel",
          "properties": {"spacing": "spacer4"},
          "schemaCode": null
        }
      ],
      "name": "viewTransaction",
      "order": 7,
      "footer": [],
      "header": [
        {
          "label": "CORE_COMMON_BACK",
          "format": "backLink",
          "onAction": [
            {"actionType": "BACK_NAVIGATION", "properties": {}}
          ]
        }
      ],
      "heading": "INVENTORY_VIEW_TRANSACTION_HEADING",
      "navigateTo": null,
      "screenType": "TEMPLATE",
      "description": "INVENTORY_VIEW_TRANSACTION_DESCRIPTION",
      "initActions": [
        {
          "actionType": "SEARCH_EVENT",
          "properties": {
            "data": [
              {
                "key": "clientCreatedBy",
                "value": "{{singleton.loggedInUserUuid}}",
                "operation": "equalsAny"
              },
              {
                "key": "referenceId",
                "value": "{{singleton.selectedProject.id}}",
                "operation": "equals"
              },
              {
                "key": "additionalFields",
                "value": "\"value\":\"REJECTED\"",
                "operation": "notContains"
              }
            ],
            "name": "stock",
            "type": "SEARCH_EVENT"
          }
        }
      ],
      "wrapperConfig": {
        "filters": [],
        "groupBy": "additionalFields.fields.mrnNumber",
        "relations": [
          {"name": "stock", "entity": "StockModel"}
        ],
        "rootEntity": "StockModel",
        "groupByType": true,
        "wrapperName": "ViewStockWrapper",
        "searchConfig": {
          "select": ["stock"],
          "orderBy": {"field": "clientCreatedTime", "order": "DESC"},
          "primary": "stock"
        }
      },
      "submitCondition": null,
      "preventScreenCapture": false
    },
    {
      "body": [
        {
          "label": "INVENTORY_STOCK_SUCCESS_LABEL",
          "format": "panelCard",
          "properties": {"type": "success"},
          "description":
              "INVENTORY_STOCK_SUCCESS_MRN_DESCRIPTION {{navigation.mrnNumber}}",
          "primaryAction": {
            "label": "INVENTORY_VIEW_TRANSACTION_LABEL",
            "onAction": [
              {
                "actionType": "NAVIGATION",
                "properties": {
                  "data": [
                    {
                      "key": "selectedStock",
                      "value": "{{navigation.mrnNumber}}"
                    },
                    {
                      "key": "clientReferenceId",
                      "value": "{{navigation.clientReferenceId}}"
                    }
                  ],
                  "name": "viewTransactionDetails",
                  "type": "TEMPLATE"
                }
              }
            ]
          },
          "secondaryAction": {
            "label": "INVENTORY_CREATE_NEW_TRANSACTION_LABEL",
            "onAction": [
              {
                "actionType": "NAVIGATION",
                "properties": {
                  "name": "manageStock",
                  "type": "TEMPLATE",
                  "navigationMode": "popUntilAndReplace",
                  "popUntilPageName": "manageStock"
                }
              }
            ]
          },
          "primaryActionLabel": "INVENTORY_VIEW_TRANSACTION_LABEL",
          "secondaryActionLabel": "INVENTORY_CREATE_NEW_TRANSACTION_LABEL"
        }
      ],
      "name": "stockSuccess",
      "order": 6,
      "footer": [],
      "header": [],
      "navigateTo": null,
      "screenType": "TEMPLATE",
      "submitCondition": null,
      "preventScreenCapture": false
    },
    {
      "body": [
        {
          "type": "error",
          "label": "INVENTORY_SCAN_RECEIVER_MISMATCH_LABEL",
          "format": "infoCard",
          "visible": "{{navigation.receiverId}} != {{fn:getUserFacilityId()}}",
          "schemaCode": null,
          "description": "INVENTORY_SCAN_RECEIVER_MISMATCH_DESCRIPTION"
        },
        {
          "type": "error",
          "label": "INVENTORY_SCAN_BOUNDARY_MISMATCH_LABEL",
          "format": "infoCard",
          "visible":
              "{{fn:isEmpty(navigation.boundaryCode)}} == false && {{fn:isScanBoundaryOutOfScope(navigation.boundaryCode)}} == true",
          "schemaCode": null,
          "description": "INVENTORY_SCAN_BOUNDARY_MISMATCH_DESCRIPTION"
        },
        {
          "type": "warning",
          "label": "INVENTORY_SCAN_ALREADY_RECEIVED_LABEL",
          "format": "infoCard",
          "visible": "{{fn:hasResults('StockModel')}} == true",
          "schemaCode": null,
          "description": "INVENTORY_SCAN_ALREADY_RECEIVED_DESCRIPTION"
        },
        {
          "format": "card",
          "children": [
            {
              "data": [
                {
                  "key": "INVENTORY_SENDER_LABEL",
                  "value": "{{fn:getFacilityName(navigation.senderId)}}"
                },
                {
                  "key": "INVENTORY_QUANTITY_LABEL",
                  "value": "{{navigation.quantity}}"
                },
                {"key": "INVENTORY_SKU_LABEL", "value": "{{navigation.sku}}"},
                {
                  "key": "INVENTORY_BATCH_LABEL",
                  "value": "{{navigation.batchNumber}}"
                },
                {
                  "key": "INVENTORY_EXPIRY_LABEL",
                  "value": "{{navigation.expiryDate}}"
                },
                {
                  "key": "INVENTORY_WAYBILL_LABEL",
                  "value": "{{navigation.waybillNumber}}"
                }
              ],
              "format": "labelPairList"
            }
          ],
          "schemaCode": null
        }
      ],
      "name": "stockScanConfirm",
      "order": 3,
      "footer": [
        {
          "label": "INVENTORY_SCAN_CONFIRM_RECEIVE_LABEL",
          "format": "button",
          "hidden":
              "{{fn:isEmpty(navigation.receiverId)}} == false && {{navigation.receiverId}} != {{fn:getUserFacilityId()}} || {{fn:hasResults('StockModel')}} == true || ({{fn:isEmpty(navigation.boundaryCode)}} == false && {{fn:isScanBoundaryOutOfScope(navigation.boundaryCode)}} == true)",
          "onAction": [
            {
              "actionType": "FETCH_TRANSFORMER_CONFIG",
              "properties": {
                "data": [
                  {"key": "stockEntryType", "value": "RECEIPT"},
                  {"key": "transactionType", "value": "RECEIVED"},
                  {"key": "primaryRole", "value": "RECEIVER"},
                  {"key": "secondaryRole", "value": "SENDER"},
                  {
                    "key": "mrnNumber",
                    "value": "{{fn:generateUniqueMaterialNoteNumber()}}"
                  },
                  {
                    "key": "senderFacilityId",
                    "value": "{{navigation.senderId}}"
                  },
                  {
                    "key": "productVariantId",
                    "value": "{{navigation.productVariantId}}"
                  },
                  {
                    "key": "userFacilityId",
                    "value": "{{fn:getUserFacilityId()}}"
                  },
                  {
                    "key": "userFacilityType",
                    "value": "{{fn:getUserFacilityType()}}"
                  },
                  {"key": "sku", "value": "{{navigation.sku}}"},
                  {"key": "quantity", "value": "{{navigation.quantity}}"},
                  {
                    "key": "waybillNumber",
                    "value": "{{navigation.waybillNumber}}"
                  },
                  {"key": "batchNumber", "value": "{{navigation.batchNumber}}"},
                  {"key": "expiryDate", "value": "{{navigation.expiryDate}}"},
                  {"key": "comments", "value": "{{navigation.comments}}"},
                  {
                    "key": "dispatchClientReferenceId",
                    "value": "{{navigation.clientReferenceId}}"
                  },
                  {
                    "key": "boundaryCode",
                    "value": "{{navigation.boundaryCode}}"
                  }
                ],
                "onError": [
                  {
                    "actionType": "SHOW_TOAST",
                    "properties": {"message": "Failed to fetch config."}
                  }
                ],
                "configName": "stockScanReceipt",
                "forceCreate": true
              }
            },
            {
              "actionType": "CREATE_EVENT",
              "properties": {
                "entity": "STOCK",
                "onError": [
                  {
                    "actionType": "SHOW_TOAST",
                    "properties": {"message": "Failed to create receipt."}
                  }
                ]
              }
            },
            {
              "actionType": "UPDATE_STOCK_BALANCE",
              "properties": {
                "entity": "STOCK",
                "onError": [
                  {
                    "actionType": "SHOW_TOAST",
                    "properties": {"message": "Failed to update stock balance."}
                  }
                ]
              }
            },
            {
              "actionType": "SHOW_TOAST",
              "properties": {
                "type": "success",
                "message": "INVENTORY_STOCK_RECEIVED_SUCCESS"
              }
            },
            {
              "actionType": "NAVIGATION",
              "properties": {
                "name": "manageStock",
                "type": "TEMPLATE",
                "navigationMode": "popUntilAndReplace",
                "popUntilPageName": "manageStock"
              }
            }
          ],
          "properties": {
            "size": "large",
            "type": "primary",
            "mainAxisSize": "max",
            "mainAxisAlignment": "center"
          }
        }
      ],
      "header": [
        {
          "label": "CORE_COMMON_BACK",
          "format": "backLink",
          "onAction": [
            {"actionType": "BACK_NAVIGATION", "properties": {}}
          ]
        }
      ],
      "heading": "INVENTORY_SCAN_CONFIRM_HEADING",
      "navigateTo": null,
      "screenType": "TEMPLATE",
      "description": "INVENTORY_SCAN_CONFIRM_DESCRIPTION",
      "initActions": [
        {
          "actionType": "SEARCH_EVENT",
          "properties": {
            "data": [
              {
                "key": "receiverId",
                "value": "{{fn:getUserFacilityId()}}",
                "operation": "equals"
              },
              {
                "key": "transactionType",
                "value": "RECEIVED",
                "operation": "equals"
              },
              {
                "key": "additionalFields",
                "value": "{{navigation.clientReferenceId}}",
                "operation": "matches"
              }
            ],
            "name": "stock",
            "type": "SEARCH_EVENT",
            "awaitResults": true,
            "skipAccumulatedFilters": true
          }
        }
      ],
      "wrapperConfig": {
        "filters": [],
        "relations": [
          {"name": "stock", "entity": "StockModel"}
        ],
        "rootEntity": "StockModel",
        "groupByType": true,
        "wrapperName": "StockScanConfirmWrapper",
        "searchConfig": {
          "select": ["stock"],
          "primary": "stock"
        }
      },
      "submitCondition": null,
      "preventScreenCapture": false
    },
    {
      "body": [
        {
          "format": "card",
          "children": [
            {
              "type": "template",
              "enums": [
                {
                  "code": "ISSUED",
                  "name":
                      "APP_CONFIG_INVENTORY_returnOrIssueSelection_OPTION_ISSUED"
                },
                {
                  "code": "RETURNED",
                  "name":
                      "APP_CONFIG_INVENTORY_returnOrIssueSelection_OPTION_RETURNED"
                }
              ],
              "label":
                  "APP_CONFIG_INVENTORY_returnOrIssueSelection_TRANSACTION_TYPE_LABEL",
              "format": "dropdownTemplate",
              "visible": "{{fn:hasRole('DISTRIBUTOR')}} == false",
              "valueKey": "code",
              "fieldName": "transactionType"
            },
            {
              "type": "template",
              "enums": [
                {
                  "code": "RETURNED",
                  "name":
                      "APP_CONFIG_INVENTORY_returnOrIssueSelection_OPTION_RETURNED"
                }
              ],
              "label":
                  "APP_CONFIG_INVENTORY_returnOrIssueSelection_TRANSACTION_TYPE_LABEL",
              "format": "dropdownTemplate",
              "visible": "{{fn:hasRole('DISTRIBUTOR')}} == true",
              "valueKey": "code",
              "fieldName": "transactionType",
              "showWhenSingleOption": true
            }
          ],
          "schemaCode": null
        }
      ],
      "name": "returnOrIssueSelection",
      "order": 2,
      "footer": [
        {
          "label":
              "APP_CONFIG_INVENTORY_returnOrIssueSelection_NEXT_BUTTON_LABEL",
          "format": "button",
          "onAction": [
            {
              "actions": [
                {
                  "actionType": "NAVIGATION",
                  "properties": {
                    "data": [
                      {"key": "stockEntryType", "value": "ISSUED"},
                      {"key": "transactionType", "value": "DISPATCHED"},
                      {"key": "primaryRole", "value": "SENDER"},
                      {"key": "secondaryRole", "value": "RECEIVER"},
                      {
                        "key": "mrnNumber",
                        "value": "{{fn:generateUniqueMaterialNoteNumber()}}"
                      },
                      {
                        "key": "stockBalances",
                        "value": "{{fn:getAllStockBalances()}}"
                      }
                    ],
                    "name": "RECORDSTOCK",
                    "type": "FORM"
                  }
                }
              ],
              "condition": {"expression": "transactionType == ISSUED"}
            },
            {
              "actions": [
                {
                  "actionType": "NAVIGATION",
                  "properties": {
                    "data": [
                      {"key": "stockEntryType", "value": "RETURNED"},
                      {"key": "transactionType", "value": "DISPATCHED"},
                      {"key": "primaryRole", "value": "SENDER"},
                      {"key": "secondaryRole", "value": "RECEIVER"},
                      {
                        "key": "mrnNumber",
                        "value": "{{fn:generateUniqueMaterialNoteNumber()}}"
                      },
                      {
                        "key": "stockBalances",
                        "value": "{{fn:getAllStockBalances()}}"
                      },
                      {
                        "key": "isDistributor",
                        "value": "{{fn:hasRole('DISTRIBUTOR')}}"
                      }
                    ],
                    "name": "RECORDSTOCK",
                    "type": "FORM"
                  }
                }
              ],
              "condition": {"expression": "transactionType == RETURNED"}
            }
          ],
          "properties": {
            "size": "large",
            "type": "primary",
            "mainAxisSize": "max",
            "mainAxisAlignment": "center"
          }
        }
      ],
      "header": [
        {
          "label": "CORE_COMMON_BACK",
          "format": "backLink",
          "onAction": [
            {"actionType": "BACK_NAVIGATION", "properties": {}}
          ]
        }
      ],
      "heading": "APP_CONFIG_INVENTORY_returnOrIssueSelection_HEADING",
      "navigateTo": null,
      "screenType": "TEMPLATE",
      "initActions": [
        {
          "actionType": "SEARCH_EVENT",
          "properties": {
            "data": [
              {
                "key": "tenantId",
                "root": "stock",
                "value": "{{singleton.tenantId}}",
                "operation": "equals"
              }
            ],
            "name": "stockSearch",
            "type": "SEARCH_EVENT",
            "select": ["stock"],
            "primary": "stock",
            "awaitResults": true,
            "skipAccumulatedFilters": true
          }
        }
      ],
      "submitCondition": null,
      "preventScreenCapture": false
    },
    {
      "body": [
        {
          "icon": "FileDownload",
          "format": "menu_card",
          "heading":
              "APP_CONFIG_INVENTORY_manageStock_RECORD_STOCK_RECEIPT_HEADING",
          "onAction": [
            {
              "actionType": "NAVIGATION",
              "properties": {
                "data": [],
                "name": "incomingTransactions",
                "type": "TEMPLATE"
              }
            }
          ],
          "schemaCode": null,
          "description":
              "APP_CONFIG_INVENTORY_manageStock_CREATE_RECORDS_FOR_STOCK_RECEIVED_AT_THE_WAREHOUSE_DESCRIPTION"
        },
        {
          "icon": "FileUpload",
          "format": "menu_card",
          "heading":
              "APP_CONFIG_INVENTORY_manageStock_RECORD_STOCK_ISSUED_HEADING",
          "onAction": [
            {
              "actionType": "NAVIGATION",
              "properties": {
                "data": [],
                "name": "returnOrIssueSelection",
                "type": "TEMPLATE"
              }
            }
          ],
          "schemaCode": null,
          "description":
              "APP_CONFIG_INVENTORY_manageStock_CREATE_RECORDS_FOR_STOCK_SENT_OUT_FROM_THE_WAREHOUSE_DESCRIPTION"
        },
        {
          "icon": "Store",
          "format": "menu_card",
          "heading":
              "APP_CONFIG_INVENTORY_manageStock_RECORD_STOCK_DAMAGED_HEADING",
          "visible": false,
          "onAction": [
            {
              "actionType": "NAVIGATION",
              "properties": {
                "data": [
                  {"key": "stockEntryType", "value": "DAMAGED"},
                  {"key": "transactionType", "value": "DISPATCHED"},
                  {"key": "primaryRole", "value": "SENDER"},
                  {"key": "secondaryRole", "value": "RECEIVER"},
                  {
                    "key": "mrnNumber",
                    "value": "{{fn:generateUniqueMaterialNoteNumber()}}"
                  }
                ],
                "name": "RECORDSTOCK",
                "type": "FORM"
              }
            }
          ],
          "schemaCode": null,
          "description":
              "APP_CONFIG_INVENTORY_manageStock_RECORD_THE_LIST_OF_RESOURCES_DAMAGED_DURING_CAMPAIGN_OPERATIONS_DESCRIPTION"
        },
        {
          "icon": "Store",
          "format": "menu_card",
          "heading":
              "APP_CONFIG_INVENTORY_manageStock_RECORD_STOCK_LOSS_HEADING",
          "visible": false,
          "onAction": [
            {
              "actionType": "NAVIGATION",
              "properties": {
                "data": [
                  {"key": "stockEntryType", "value": "LOSS"},
                  {"key": "transactionType", "value": "DISPATCHED"},
                  {"key": "primaryRole", "value": "SENDER"},
                  {"key": "secondaryRole", "value": "RECEIVER"},
                  {
                    "key": "mrnNumber",
                    "value": "{{fn:generateUniqueMaterialNoteNumber()}}"
                  }
                ],
                "name": "RECORDSTOCK",
                "type": "FORM"
              }
            }
          ],
          "schemaCode": null,
          "description":
              "APP_CONFIG_INVENTORY_manageStock_RECORD_THE_LIST_OF_RESOURCES_LOST_DURING_CAMPAIGN_OPERATIONS_DESCRIPTION"
        },
        {
          "icon": "Store",
          "format": "menu_card",
          "heading": "INVENTORY_RECORD_LESS_EXCESS_HEADING",
          "visible": false,
          "onAction": [
            {
              "actionType": "NAVIGATION",
              "properties": {
                "data": [
                  {"key": "stockEntryType", "value": "LESS_EXCESS"},
                  {"key": "transactionType", "value": "RECEIVED"},
                  {"key": "primaryRole", "value": "SENDER"},
                  {"key": "secondaryRole", "value": "RECEIVER"},
                  {
                    "key": "mrnNumber",
                    "value": "{{fn:generateUniqueMaterialNoteNumber()}}"
                  }
                ],
                "name": "RECORDLESSEXCESS",
                "type": "FORM"
              }
            }
          ],
          "schemaCode": null,
          "description": "INVENTORY_RECORD_LESS_EXCESS_DESCRIPTION"
        }
      ],
      "name": "manageStock",
      "order": 1,
      "footer": [
        {
          "label":
              "APP_CONFIG_INVENTORY_manageStock_VIEW_TRANSACTIONS_FOOTER_BUTTON_LABEL",
          "format": "button",
          "onAction": [
            {
              "actionType": "NAVIGATION",
              "properties": {
                "data": [],
                "name": "viewTransaction",
                "type": "TEMPLATE",
                "navigationMode": "popUntilAndPush",
                "popUntilPageName": "viewTransaction"
              }
            }
          ],
          "properties": {
            "size": "large",
            "type": "primary",
            "mainAxisSize": "max",
            "mainAxisAlignment": "center"
          }
        }
      ],
      "header": [
        {
          "label": "APP_CONFIG_INVENTORY_manageStock_BACK_BUTTON_LABEL",
          "format": "backLink",
          "onAction": [
            {
              "actionType": "BACK_NAVIGATION",
              "properties": {"name": "HOME", "type": "HOME"}
            }
          ]
        }
      ],
      "heading": "APP_CONFIG_INVENTORY_manageStock_HEADING",
      "navigateTo": null,
      "screenType": "TEMPLATE",
      "initActions": [
        {
          "actionType": "SEARCH_EVENT",
          "properties": {
            "data": [
              {
                "key": "projectId",
                "value": "{{singleton.selectedProject.id}}",
                "operation": "equals"
              }
            ],
            "name": "projectFacility",
            "type": "SEARCH_EVENT",
            "awaitResults": true,
            "skipAccumulatedFilters": true
          }
        }
      ],
      "wrapperConfig": {
        "filters": [],
        "relations": [
          {
            "name": "facility",
            "match": {"field": "id", "equalsFrom": "facilityId"},
            "entity": "FacilityModel"
          },
          {
            "name": "productVariant",
            "match": {"field": "id", "equalsFrom": "resource"},
            "entity": "ProductVariantModel"
          }
        ],
        "rootEntity": "ProjectFacilityModel",
        "groupByType": true,
        "wrapperName": "InventoryWrapper",
        "searchConfig": {
          "select": ["projectFacility", "productVariant", "stock"],
          "primary": "projectFacility"
        }
      },
      "submitCondition": null,
      "preventScreenCapture": false
    },
    {
      "name": "stockReceiptDetails",
      "order": 1,
      "pages": [
        {
          "body": null,
          "flow": "stockReceiptDetails",
          "page": "stockReceiptDetails",
          "type": "object",
          "label": "INVENTORY_STOCK_RECEIPT_DETAILS_HEADING",
          "order": 1,
          "footer": [
            {
              "label": "INVENTORY_ACCEPT_STOCK_LABEL",
              "format": "button",
              "onAction": [],
              "properties": {
                "size": "large",
                "type": "primary",
                "mainAxisSize": "max",
                "mainAxisAlignment": "center"
              }
            },
            {
              "label": "INVENTORY_DECLINE_STOCK_LABEL",
              "format": "button",
              "onAction": [],
              "properties": {
                "size": "large",
                "type": "secondary",
                "mainAxisSize": "max",
                "mainAxisAlignment": "center"
              }
            }
          ],
          "module": "INVENTORY",
          "heading": "INVENTORY_STOCK_RECEIPT_DETAILS_HEADING",
          "project": "CMP-2026-10-30-001379",
          "summary": false,
          "version": 1,
          "onAction": [
            {
              "actionType": "FETCH_TRANSFORMER_CONFIG",
              "properties": {
                "data": [
                  {"key": "stockEntryType", "value": "RECEIPT"},
                  {"key": "transactionType", "value": "RECEIVED"},
                  {"key": "primaryRole", "value": "RECEIVER"},
                  {"key": "secondaryRole", "value": "SENDER"},
                  {
                    "key": "mrnNumber",
                    "value": "{{fn:generateUniqueMaterialNoteNumber()}}"
                  },
                  {
                    "key": "senderFacilityId",
                    "value": "{{navigation.senderFacilityId}}"
                  },
                  {
                    "key": "productVariantId",
                    "value": "{{navigation.productVariantId}}"
                  },
                  {
                    "key": "userFacilityId",
                    "value": "{{fn:getUserFacilityId()}}"
                  },
                  {
                    "key": "userFacilityType",
                    "value": "{{fn:getUserFacilityType()}}"
                  },
                  {"key": "sku", "value": "{{navigation.sku}}"},
                  {"key": "quantity", "value": "{{navigation.quantity}}"},
                  {
                    "key": "dispatchClientReferenceId",
                    "value": "{{navigation.clientReferenceId}}"
                  }
                ],
                "onError": [
                  {
                    "actionType": "SHOW_TOAST",
                    "properties": {"message": "Failed to fetch config."}
                  }
                ],
                "configName": "stockReceipt",
                "forceCreate": true
              }
            },
            {
              "actionType": "CREATE_EVENT",
              "properties": {
                "entity": "STOCK",
                "onError": [
                  {
                    "actionType": "SHOW_TOAST",
                    "properties": {"message": "Failed to create receipt."}
                  }
                ]
              }
            },
            {
              "actionType": "UPDATE_EVENT",
              "properties": {
                "entity": "StockModel",
                "modify": [
                  {
                    "key": "StockModel.additionalFields.fields.status",
                    "value": "ACCEPTED"
                  },
                  {
                    "key": "StockModel.additionalFields.fields.mrnNumber",
                    "value": "{{fn:generateUniqueMaterialNoteNumber()}}"
                  }
                ],
                "source": "existingModels"
              }
            },
            {
              "actionType": "UPDATE_STOCK_BALANCE",
              "properties": {
                "entity": "STOCK",
                "onError": [
                  {
                    "actionType": "SHOW_TOAST",
                    "properties": {"message": "Failed to update stock balance."}
                  }
                ]
              }
            },
            {
              "actionType": "NAVIGATION",
              "properties": {
                "name": "stock-acknowledgement",
                "type": "TEMPLATE",
                "navigationMode": "popUntilAndReplace",
                "popUntilPageName": "manageStock"
              }
            }
          ],
          "properties": [
            {
              "type": "string",
              "label": "INVENTORY_RESOURCE_LABEL",
              "order": 1,
              "value": "{{sku}}",
              "format": "text",
              "hidden": false,
              "isMdms": false,
              "tooltip": "",
              "helpText": "",
              "infoText": "",
              "readOnly": false,
              "fieldName": "resource",
              "mandatory": false,
              "deleteFlag": false,
              "innerLabel": "",
              "schemaCode": null,
              "systemDate": false,
              "displayOnly": true,
              "validations": [],
              "errorMessage": ""
            },
            {
              "type": "string",
              "label": "INVENTORY_MATERIAL_ISSUE_NUMBER_LABEL",
              "order": 2,
              "value": "{{mrnNumber}}",
              "format": "text",
              "hidden": true,
              "isMdms": false,
              "tooltip": "",
              "helpText": "",
              "infoText": "",
              "readOnly": false,
              "fieldName": "materialIssueNumber",
              "mandatory": false,
              "deleteFlag": false,
              "innerLabel": "",
              "schemaCode": null,
              "systemDate": false,
              "displayOnly": true,
              "validations": [],
              "errorMessage": ""
            },
            {
              "type": "string",
              "label": "INVENTORY_RECEIVED_FROM_LABEL",
              "order": 3,
              "value": "{{senderFacilityId}}",
              "format": "text",
              "hidden": false,
              "isMdms": false,
              "tooltip": "",
              "helpText": "",
              "infoText": "",
              "readOnly": false,
              "fieldName": "receivedFrom",
              "mandatory": false,
              "deleteFlag": false,
              "innerLabel": "",
              "schemaCode": null,
              "systemDate": false,
              "displayOnly": true,
              "validations": [],
              "errorMessage": ""
            },
            {
              "type": "string",
              "enums": null,
              "label": "INVENTORY_WAYBILL_NUMBER_LABEL",
              "order": 4,
              "value": "",
              "format": "text",
              "hidden": false,
              "isMdms": false,
              "tooltip": "",
              "helpText": "",
              "infoText": "",
              "readOnly": false,
              "required": true,
              "fieldName": "wayBillNumber",
              "mandatory": false,
              "deleteFlag": false,
              "innerLabel": "",
              "schemaCode": null,
              "systemDate": false,
              "validations": [
                {
                  "type": "required",
                  "value": true,
                  "message": "FIELD_REQUIRED_MESSAGE_1793359981887"
                }
              ],
              "errorMessage": "",
              "isMultiSelect": false,
              "required.message": "FIELD_REQUIRED_MESSAGE_1793359981887",
              "visibilityCondition": {}
            },
            {
              "type": "string",
              "enums": null,
              "label": "INVENTORY_BATCH_NUMBER_LABEL",
              "order": 5,
              "value": "",
              "format": "text",
              "hidden": true,
              "isMdms": false,
              "tooltip": "",
              "helpText": "",
              "infoText": "",
              "readOnly": false,
              "fieldName": "batchNumber",
              "mandatory": false,
              "deleteFlag": false,
              "innerLabel": "",
              "schemaCode": null,
              "systemDate": false,
              "validations": [],
              "errorMessage": "",
              "isMultiSelect": false,
              "visibilityCondition": {}
            },
            {
              "type": "string",
              "enums": null,
              "label": "INVENTORY_EXPIRY_LABEL",
              "order": 6,
              "value": "",
              "format": "date",
              "hidden": true,
              "isMdms": false,
              "tooltip": "",
              "helpText": "",
              "infoText": "",
              "readOnly": false,
              "fieldName": "expiryDate",
              "mandatory": false,
              "deleteFlag": false,
              "innerLabel": "",
              "schemaCode": null,
              "systemDate": false,
              "validations": [],
              "errorMessage": "",
              "isMultiSelect": false,
              "visibilityCondition": {}
            },
            {
              "type": "integer",
              "enums": null,
              "label": "INVENTORY_QUANTITY_SENT_BY_WAREHOUSE_LABEL",
              "order": 7,
              "regex": r"^[0-9]+$",
              "value": "",
              "format": "text",
              "hidden": false,
              "isMdms": false,
              "tooltip": "",
              "helpText": "",
              "infoText": "",
              "readOnly": true,
              "required": false,
              "fieldName": "quantity",
              "mandatory": false,
              "deleteFlag": false,
              "innerLabel": "",
              "schemaCode": null,
              "systemDate": false,
              "validations": [
                {
                  "type": "regex",
                  "value": r"^[0-9]+$",
                  "message": "Please enter a valid number"
                }
              ],
              "errorMessage": "",
              "isMultiSelect": false,
              "regex.message": "Please enter a valid number",
              "required.message": "Quantity is required",
              "visibilityCondition": {}
            },
            {
              "id": "109d88bf-eaec-4e13-b186-f62783486403",
              "type": "integer",
              "label":
                  "CMP-2026-10-30-001379_STOCKRECEIPTDETAILS_STOCKRECEIPTDETAILS.STOCKRECEIPTDETAILS_D85B2AA4-6355-4A30-AA82-F35CD52D633B",
              "order": 8,
              "value": "",
              "active": true,
              "format": "text",
              "hidden": false,
              "tooltip": "",
              "helpText": "",
              "infoText": "",
              "jsonPath": "field_1793360014225",
              "readOnly": false,
              "required": true,
              "fieldName":
                  "quantitée_reçue_cmp-2026-10-30-001379_stockreceiptdetails_stockreceiptdetails_9",
              "mandatory": false,
              "deleteFlag": true,
              "innerLabel": "",
              "schemaCode": null,
              "systemDate": false,
              "validations": [
                {
                  "type": "required",
                  "value": true,
                  "message": "FIELD_REQUIRED_MESSAGE_1793360078595"
                }
              ],
              "errorMessage": "",
              "required.message": "FIELD_REQUIRED_MESSAGE_1793360078595"
            },
            {
              "type": "string",
              "enums": null,
              "label": "INVENTORY_COMMENTS_LABEL",
              "order": 9,
              "value": "",
              "format": "textArea",
              "hidden": false,
              "isMdms": false,
              "tooltip": "",
              "helpText": "",
              "infoText": "",
              "readOnly": false,
              "required": false,
              "fieldName": "comment",
              "mandatory": false,
              "deleteFlag": false,
              "innerLabel": "",
              "schemaCode": null,
              "systemDate": false,
              "validations": [],
              "errorMessage": "",
              "isMultiSelect": false,
              "visibilityCondition": {}
            }
          ],
          "actionLabel": "INVENTORY_ACCEPT_STOCK_LABEL",
          "description": "",
          "showTabView": false,
          "showAlertPopUp": {
            "title": "INVENTORY_ACCEPT_CONFIRMATION_TITLE",
            "description": "INVENTORY_ACCEPT_CONFIRMATION_DESCRIPTION",
            "primaryActionLabel": "INVENTORY_ACCEPT_CONFIRM_ACTION",
            "secondaryActionLabel": "INVENTORY_ACCEPT_CANCEL_ACTION"
          },
          "submitCondition": null,
          "onSecondaryAction": [
            {
              "actionType": "FETCH_TRANSFORMER_CONFIG",
              "properties": {
                "data": [
                  {"key": "transactionType", "value": "DISPATCHED"},
                  {"key": "primaryRole", "value": "SENDER"},
                  {"key": "secondaryRole", "value": "RECEIVER"},
                  {"key": "mrnNumber", "value": "{{navigation.mrnNumber}}"},
                  {
                    "key": "senderFacilityId",
                    "value": "{{fn:getUserFacilityId()}}"
                  },
                  {
                    "key": "receiverFacilityId",
                    "value": "{{navigation.senderFacilityId}}"
                  },
                  {
                    "key": "productVariantId",
                    "value": "{{navigation.productVariantId}}"
                  },
                  {
                    "key": "userFacilityId",
                    "value": "{{fn:getUserFacilityId()}}"
                  },
                  {
                    "key": "userFacilityType",
                    "value": "{{fn:getUserFacilityType()}}"
                  },
                  {"key": "sku", "value": "{{navigation.sku}}"},
                  {"key": "quantity", "value": "{{navigation.quantity}}"}
                ],
                "onError": [
                  {
                    "actionType": "SHOW_TOAST",
                    "properties": {"message": "Failed to fetch config."}
                  }
                ],
                "configName": "stockReject",
                "forceCreate": true
              }
            },
            {
              "actionType": "UPDATE_EVENT",
              "properties": {
                "entity": "StockModel",
                "modify": [
                  {
                    "key": "StockModel.additionalFields.fields.status",
                    "value": "REJECTED"
                  }
                ],
                "source": "existingModels"
              }
            },
            {
              "actionType": "SHOW_TOAST",
              "properties": {
                "type": "success",
                "message": "INVENTORY_STOCK_REJECTED_SUCCESS"
              }
            },
            {
              "actionType": "NAVIGATION",
              "properties": {
                "name": "manageStock",
                "type": "TEMPLATE",
                "navigationMode": "popUntilAndReplace",
                "popUntilPageName": "manageStock"
              }
            }
          ],
          "preventScreenCapture": false,
          "secondaryActionLabel": "INVENTORY_DECLINE_STOCK_LABEL",
          "conditionalNavigateTo": null,
          "showSecondaryAlertPopUp": {
            "body": [
              {
                "type": "string",
                "label": "INVENTORY_REJECT_COMMENT_LABEL",
                "format": "textArea",
                "fieldName": "rejectComment",
                "mandatory": true
              }
            ],
            "title": "INVENTORY_REJECT_CONFIRMATION_TITLE",
            "description": "INVENTORY_REJECT_CONFIRMATION_DESCRIPTION",
            "primaryActionLabel": "INVENTORY_REJECT_CONFIRM_ACTION",
            "secondaryActionLabel": "INVENTORY_REJECT_CANCEL_ACTION"
          }
        }
      ],
      "project": "CMP-2026-10-30-001379",
      "summary": false,
      "version": 3,
      "disabled": false,
      "onAction": [
        {
          "actionType": "FETCH_TRANSFORMER_CONFIG",
          "properties": {
            "data": [
              {"key": "stockEntryType", "value": "RECEIPT"},
              {"key": "transactionType", "value": "RECEIVED"},
              {"key": "primaryRole", "value": "RECEIVER"},
              {"key": "secondaryRole", "value": "SENDER"},
              {
                "key": "mrnNumber",
                "value": "{{fn:generateUniqueMaterialNoteNumber()}}"
              },
              {
                "key": "senderFacilityId",
                "value": "{{navigation.senderFacilityId}}"
              },
              {
                "key": "productVariantId",
                "value": "{{navigation.productVariantId}}"
              },
              {"key": "userFacilityId", "value": "{{fn:getUserFacilityId()}}"},
              {
                "key": "userFacilityType",
                "value": "{{fn:getUserFacilityType()}}"
              },
              {"key": "sku", "value": "{{navigation.sku}}"},
              {"key": "quantity", "value": "{{navigation.quantity}}"},
              {
                "key": "dispatchClientReferenceId",
                "value": "{{navigation.clientReferenceId}}"
              }
            ],
            "onError": [
              {
                "actionType": "SHOW_TOAST",
                "properties": {"message": "Failed to fetch config."}
              }
            ],
            "configName": "stockReceipt",
            "forceCreate": true
          }
        },
        {
          "actionType": "CREATE_EVENT",
          "properties": {
            "entity": "STOCK",
            "onError": [
              {
                "actionType": "SHOW_TOAST",
                "properties": {"message": "Failed to create receipt."}
              }
            ]
          }
        },
        {
          "actionType": "UPDATE_EVENT",
          "properties": {
            "entity": "StockModel",
            "modify": [
              {
                "key": "StockModel.additionalFields.fields.status",
                "value": "ACCEPTED"
              },
              {
                "key": "StockModel.additionalFields.fields.mrnNumber",
                "value": "{{fn:generateUniqueMaterialNoteNumber()}}"
              }
            ],
            "source": "existingModels"
          }
        },
        {
          "actionType": "UPDATE_STOCK_BALANCE",
          "properties": {
            "entity": "STOCK",
            "onError": [
              {
                "actionType": "SHOW_TOAST",
                "properties": {"message": "Failed to update stock balance."}
              }
            ]
          }
        },
        {
          "actionType": "NAVIGATION",
          "properties": {
            "name": "stock-acknowledgement",
            "type": "TEMPLATE",
            "navigationMode": "popUntilAndReplace",
            "popUntilPageName": "manageStock"
          }
        }
      ],
      "isSelected": true,
      "screenType": "FORM",
      "initActions": [
        {
          "actionType": "SEARCH_EVENT",
          "properties": {
            "data": [
              {
                "key": "clientReferenceId",
                "value": "{{navigation.clientReferenceId}}",
                "operation": "equals"
              }
            ],
            "name": "stock",
            "type": "SEARCH_EVENT",
            "awaitResults": true
          }
        }
      ],
      "wrapperConfig": {
        "filters": [],
        "relations": [
          {"name": "stock", "entity": "StockModel"}
        ],
        "rootEntity": "StockModel",
        "groupByType": false,
        "wrapperName": "StockReceiptDetailsWrapper",
        "searchConfig": {
          "select": ["stock"],
          "primary": "stock"
        }
      },
      "scrollListener": {},
      "onSecondaryAction": [
        {
          "actionType": "FETCH_TRANSFORMER_CONFIG",
          "properties": {
            "data": [
              {"key": "transactionType", "value": "DISPATCHED"},
              {"key": "primaryRole", "value": "SENDER"},
              {"key": "secondaryRole", "value": "RECEIVER"},
              {"key": "mrnNumber", "value": "{{navigation.mrnNumber}}"},
              {
                "key": "senderFacilityId",
                "value": "{{fn:getUserFacilityId()}}"
              },
              {
                "key": "receiverFacilityId",
                "value": "{{navigation.senderFacilityId}}"
              },
              {
                "key": "productVariantId",
                "value": "{{navigation.productVariantId}}"
              },
              {"key": "userFacilityId", "value": "{{fn:getUserFacilityId()}}"},
              {
                "key": "userFacilityType",
                "value": "{{fn:getUserFacilityType()}}"
              },
              {"key": "sku", "value": "{{navigation.sku}}"},
              {"key": "quantity", "value": "{{navigation.quantity}}"}
            ],
            "onError": [
              {
                "actionType": "SHOW_TOAST",
                "properties": {"message": "Failed to fetch config."}
              }
            ],
            "configName": "stockReject",
            "forceCreate": true
          }
        },
        {
          "actionType": "UPDATE_EVENT",
          "properties": {
            "entity": "StockModel",
            "modify": [
              {
                "key": "StockModel.additionalFields.fields.status",
                "value": "REJECTED"
              }
            ],
            "source": "existingModels"
          }
        },
        {
          "actionType": "SHOW_TOAST",
          "properties": {
            "type": "success",
            "message": "INVENTORY_STOCK_REJECTED_SUCCESS"
          }
        },
        {
          "actionType": "NAVIGATION",
          "properties": {
            "name": "manageStock",
            "type": "TEMPLATE",
            "navigationMode": "popUntilAndReplace",
            "popUntilPageName": "manageStock"
          }
        }
      ]
    },
    {
      "name": "RECORDLESSEXCESS",
      "order": 2,
      "pages": [
        {
          "body": null,
          "flow": "RECORDLESSEXCESS",
          "page": "lessExcessDetails",
          "type": "object",
          "label": "INVENTORY_LESS_EXCESS_DETAILS_HEADING",
          "order": 2,
          "footer": [
            {
              "label": "CORE_COMMON_SUBMIT",
              "format": "button",
              "onAction": [
                {
                  "actionType": "NAVIGATION",
                  "properties": {
                    "name": "stock-acknowledgement",
                    "type": "template"
                  }
                }
              ],
              "properties": {
                "size": "large",
                "type": "primary",
                "mainAxisSize": "max",
                "mainAxisAlignment": "center"
              }
            }
          ],
          "module": "INVENTORY",
          "heading": "INVENTORY_LESS_EXCESS_DETAILS_HEADING",
          "project": "CMP-2026-10-30-001379",
          "summary": false,
          "version": 1,
          "onAction": [
            {
              "actionType": "FETCH_TRANSFORMER_CONFIG",
              "properties": {
                "data": [
                  {
                    "key": "stockEntryType",
                    "value": "{{formData.lessExcessDetails.recordType}}"
                  },
                  {"key": "mrnNumber", "value": "{{navigation.mrnNumber}}"}
                ],
                "onError": [
                  {
                    "actionType": "SHOW_TOAST",
                    "properties": {"message": "Failed to fetch config."}
                  }
                ],
                "configName": "stockLessExcess"
              }
            },
            {
              "actionType": "CREATE_EVENT",
              "properties": {
                "entity": "STOCK",
                "onError": [
                  {
                    "actionType": "SHOW_TOAST",
                    "properties": {"message": "Failed to create stock."}
                  }
                ]
              }
            },
            {
              "actionType": "UPDATE_STOCK_BALANCE",
              "properties": {
                "entity": "STOCK",
                "onError": [
                  {
                    "actionType": "SHOW_TOAST",
                    "properties": {"message": "Failed to update stock balance."}
                  }
                ]
              }
            },
            {
              "actionType": "NAVIGATION",
              "properties": {
                "data": [
                  {"key": "mrnNumber", "value": "{{navigation.mrnNumber}}"}
                ],
                "name": "stockSuccess",
                "type": "TEMPLATE",
                "onError": [
                  {
                    "actionType": "SHOW_TOAST",
                    "properties": {"message": "Navigation failed."}
                  }
                ],
                "navigationMode": "popUntilAndPush",
                "popUntilPageName": "manageStock"
              }
            }
          ],
          "navigateTo": {"name": "stock-acknowledgement", "type": "template"},
          "properties": [
            {
              "type": "string",
              "enums": [
                {"code": "LESS", "name": "Less"},
                {"code": "EXCESS", "name": "Excess"}
              ],
              "label": "INVENTORY_WHAT_ARE_YOU_RECORDING_LABEL",
              "order": 1,
              "value": "",
              "format": "dropdown",
              "hidden": false,
              "isMdms": false,
              "tooltip": "",
              "helpText": "",
              "infoText": "",
              "readOnly": false,
              "required": true,
              "fieldName": "recordType",
              "mandatory": false,
              "deleteFlag": false,
              "innerLabel": "",
              "schemaCode": null,
              "systemDate": false,
              "validations": [
                {
                  "type": "required",
                  "value": true,
                  "message": "INVENTORY_RECORD_TYPE_REQUIRED_MESSAGE"
                }
              ],
              "errorMessage": "",
              "isMultiSelect": false,
              "dropDownOptions": [
                {"code": "LESS", "name": "Less"},
                {"code": "EXCESS", "name": "Excess"}
              ],
              "required.message": "INVENTORY_RECORD_TYPE_REQUIRED_MESSAGE"
            },
            {
              "type": "dynamic",
              "enums": null,
              "label": "APPONE_INVENTORY_PRODUCTDETAILS_LABEL",
              "order": 2,
              "value": "",
              "format": "custom",
              "hidden": false,
              "isMdms": true,
              "tooltip": "",
              "helpText": "",
              "infoText": "",
              "readOnly": false,
              "required": true,
              "fieldName": "productVariant",
              "mandatory": false,
              "deleteFlag": false,
              "innerLabel": "",
              "schemaCode": "HCM.DELIVERY_COMMENT_OPTIONS_POPULATOR",
              "systemDate": false,
              "validations": [
                {
                  "type": "required",
                  "value": true,
                  "message": "INVENTORY_PRODUCT_VARIANT_REQUIRED_MESSAGE"
                }
              ],
              "errorMessage": "",
              "isMultiSelect": false,
              "dropDownOptions": [],
              "required.message": "INVENTORY_PRODUCT_VARIANT_REQUIRED_MESSAGE"
            },
            {
              "type": "dynamic",
              "enums": null,
              "label": "APPONE_MANAGESTOCK_WAREHOUSE_label_facilityFromWhich",
              "order": 3,
              "value": "",
              "format": "custom",
              "hidden": false,
              "isMdms": true,
              "tooltip": "",
              "helpText": "",
              "infoText": "",
              "readOnly": false,
              "required": true,
              "fieldName": "facilityFromWhich",
              "mandatory": false,
              "deleteFlag": false,
              "innerLabel": "",
              "schemaCode": "HCM.FACILITY_OPTIONS_POPULATOR",
              "systemDate": false,
              "validations": [
                {
                  "type": "required",
                  "value": true,
                  "message":
                      "APPONE_MANAGESTOCK_WAREHOUSE_label_facilityToWhich_mandatory_message"
                }
              ],
              "errorMessage": "",
              "includeInForm": true,
              "isMultiSelect": false,
              "required.message":
                  "APPONE_MANAGESTOCK_WAREHOUSE_label_facilityToWhich_mandatory_message"
            },
            {
              "type": "string",
              "enums": [],
              "label": "APPONE_MANAGESTOCK_WAREHOUSE_label_deliveryTeamCode",
              "order": 4,
              "value": "",
              "format": "scanner",
              "hidden": false,
              "isMdms": false,
              "tooltip": "",
              "helpText": "",
              "infoText": "",
              "readOnly": false,
              "required": true,
              "fieldName": "deliveryTeam",
              "mandatory": false,
              "deleteFlag": false,
              "innerLabel": "",
              "schemaCode": null,
              "systemDate": false,
              "validations": [
                {
                  "type": "required",
                  "value": true,
                  "message":
                      "APPONE_MANAGESTOCK_WAREHOUSE_label_facilityFromWhich_mandatory_message"
                },
                {
                  "type": "identityQr",
                  "value": true,
                  "message":
                      "APPONE_MANAGESTOCK_WAREHOUSE_label_teamCode_invalid_qr_message"
                }
              ],
              "errorMessage": "",
              "isMultiSelect": false,
              "dropDownOptions": [],
              "required.message":
                  "APPONE_MANAGESTOCK_WAREHOUSE_label_facilityFromWhich_mandatory_message",
              "visibilityCondition": {
                "expression": [
                  {
                    "condition":
                        "lessExcessDetails.facilityFromWhich==DELIVERY_TEAM"
                  }
                ]
              }
            },
            {
              "type": "integer",
              "enums": null,
              "label": "INVENTORY_QUANTITY_LABEL",
              "order": 5,
              "regex": r"^[0-9]+$",
              "value": "",
              "format": "text",
              "hidden": false,
              "isMdms": false,
              "tooltip": "",
              "helpText": "",
              "infoText": "",
              "readOnly": false,
              "required": true,
              "fieldName": "quantity",
              "mandatory": false,
              "deleteFlag": false,
              "innerLabel": "",
              "schemaCode": null,
              "systemDate": false,
              "validations": [
                {
                  "type": "required",
                  "value": true,
                  "message": "INVENTORY_QUANTITY_REQUIRED_MESSAGE"
                },
                {
                  "type": "regex",
                  "value": r"^[0-9]+$",
                  "message": "Please enter a valid number"
                }
              ],
              "errorMessage": "",
              "isMultiSelect": false,
              "regex.message": "Please enter a valid number",
              "required.message": "INVENTORY_QUANTITY_REQUIRED_MESSAGE"
            },
            {
              "type": "string",
              "enums": null,
              "label": "INVENTORY_REASON_FOR_LESS_EXCESS_LABEL",
              "order": 6,
              "value": "",
              "format": "text",
              "hidden": false,
              "isMdms": false,
              "tooltip": "",
              "helpText": "",
              "infoText": "",
              "readOnly": false,
              "required": true,
              "fieldName": "reasonForLessExcess",
              "mandatory": false,
              "deleteFlag": false,
              "innerLabel": "",
              "schemaCode": null,
              "systemDate": false,
              "validations": [
                {
                  "type": "required",
                  "value": true,
                  "message": "INVENTORY_REASON_REQUIRED_MESSAGE"
                }
              ],
              "errorMessage": "",
              "isMultiSelect": false,
              "required.message": "INVENTORY_REASON_REQUIRED_MESSAGE"
            }
          ],
          "actionLabel": "CORE_COMMON_SUBMIT",
          "description": "INVENTORY_LESS_EXCESS_DETAILS_DESCRIPTION",
          "showTabView": false,
          "submitCondition": null,
          "preventScreenCapture": false,
          "conditionalNavigateTo": null
        },
        {
          "body": null,
          "flow": "RECORDLESSEXCESS",
          "page": "warehouseDetails",
          "type": "object",
          "label": "APPONE_MANAGESTOCK_WAREHOUSE_SCREEN_HEADING",
          "order": 1,
          "footer": [
            {
              "label": "APPONE_MANAGESTOCK_WAREHOUSE_ACTION_BUTTON_LABEL_1",
              "format": "button",
              "onAction": [
                {
                  "actionType": "NAVIGATION",
                  "properties": {"name": "lessExcessDetails", "type": "form"}
                }
              ],
              "properties": {
                "size": "large",
                "type": "primary",
                "mainAxisSize": "max",
                "mainAxisAlignment": "center"
              }
            }
          ],
          "module": "INVENTORY",
          "heading": "APPONE_MANAGESTOCK_WAREHOUSE_SCREEN_HEADING",
          "project": "CMP-2026-10-30-001379",
          "summary": false,
          "version": 1,
          "onAction": [
            {
              "actionType": "FETCH_TRANSFORMER_CONFIG",
              "properties": {
                "data": [
                  {
                    "key": "stockEntryType",
                    "value": "{{formData.lessExcessDetails.recordType}}"
                  },
                  {"key": "mrnNumber", "value": "{{navigation.mrnNumber}}"}
                ],
                "onError": [
                  {
                    "actionType": "SHOW_TOAST",
                    "properties": {"message": "Failed to fetch config."}
                  }
                ],
                "configName": "stockLessExcess"
              }
            },
            {
              "actionType": "CREATE_EVENT",
              "properties": {
                "entity": "STOCK",
                "onError": [
                  {
                    "actionType": "SHOW_TOAST",
                    "properties": {"message": "Failed to create stock."}
                  }
                ]
              }
            },
            {
              "actionType": "UPDATE_STOCK_BALANCE",
              "properties": {
                "entity": "STOCK",
                "onError": [
                  {
                    "actionType": "SHOW_TOAST",
                    "properties": {"message": "Failed to update stock balance."}
                  }
                ]
              }
            },
            {
              "actionType": "NAVIGATION",
              "properties": {
                "data": [
                  {"key": "mrnNumber", "value": "{{navigation.mrnNumber}}"}
                ],
                "name": "stockSuccess",
                "type": "TEMPLATE",
                "onError": [
                  {
                    "actionType": "SHOW_TOAST",
                    "properties": {"message": "Navigation failed."}
                  }
                ],
                "navigationMode": "popUntilAndPush",
                "popUntilPageName": "manageStock"
              }
            }
          ],
          "navigateTo": {"name": "lessExcessDetails", "type": "form"},
          "properties": [
            {
              "type": "integer",
              "label": "APPONE_MANAGESTOCK_WAREHOUSE_label_dateOfReceipt",
              "order": 1,
              "value": "",
              "format": "date",
              "hidden": false,
              "isMdms": false,
              "tooltip": "",
              "helpText": "",
              "infoText": "",
              "readOnly": true,
              "required": true,
              "fieldName": "dateOfEntry",
              "mandatory": false,
              "deleteFlag": false,
              "innerLabel": "",
              "schemaCode": null,
              "systemDate": true,
              "validations": [
                {
                  "type": "required",
                  "value": true,
                  "message":
                      "APPONE_MANAGESTOCK_WAREHOUSE_label_dateOfReceipt_mandatory_message"
                }
              ],
              "errorMessage": "",
              "includeInForm": true,
              "isMultiSelect": false,
              "required.message":
                  "APPONE_MANAGESTOCK_WAREHOUSE_label_dateOfReceipt_mandatory_message"
            },
            {
              "type": "string",
              "label": "APPONE_MANAGESTOCK_WAREHOUSE_label_administrativeArea",
              "order": 2,
              "value": "",
              "format": "locality",
              "hidden": false,
              "isMdms": false,
              "tooltip": "",
              "helpText": "",
              "infoText": "",
              "readOnly": false,
              "required": true,
              "fieldName": "administrativeArea",
              "mandatory": false,
              "deleteFlag": false,
              "innerLabel": "",
              "schemaCode": null,
              "systemDate": false,
              "validations": [
                {
                  "type": "required",
                  "value": true,
                  "message":
                      "APPONE_MANAGESTOCK_WAREHOUSE_label_administrativeArea_mandatory_message"
                }
              ],
              "errorMessage": "",
              "includeInForm": true,
              "isMultiSelect": false,
              "required.message":
                  "APPONE_MANAGESTOCK_WAREHOUSE_label_administrativeArea_mandatory_message"
            },
            {
              "type": "dynamic",
              "enums": [],
              "label": "APPONE_MANAGESTOCK_WAREHOUSE_label_facilityToWhich",
              "order": 3,
              "value": "",
              "format": "custom",
              "hidden": false,
              "isMdms": false,
              "tooltip": "",
              "helpText": "",
              "infoText": "",
              "readOnly": false,
              "required": true,
              "fieldName": "facilityToWhich",
              "mandatory": false,
              "deleteFlag": false,
              "innerLabel": "",
              "schemaCode": null,
              "systemDate": false,
              "validations": [
                {
                  "type": "required",
                  "value": true,
                  "message":
                      "APPONE_MANAGESTOCK_WAREHOUSE_label_facilityToWhich_mandatory_message"
                }
              ],
              "errorMessage": "",
              "includeInForm": true,
              "isMultiSelect": false,
              "dropDownOptions": [],
              "required.message":
                  "APPONE_MANAGESTOCK_WAREHOUSE_label_facilityToWhich_mandatory_message"
            },
            {
              "type": "string",
              "enums": [],
              "label": "APP_CONFIG_INVENTORY_warehouseDetails_teamCode_LABEL",
              "order": 4,
              "value": "",
              "format": "scanner",
              "hidden": false,
              "isMdms": false,
              "tooltip": "",
              "helpText": "",
              "infoText": "",
              "readOnly": false,
              "required": true,
              "fieldName": "teamCode",
              "mandatory": false,
              "deleteFlag": false,
              "innerLabel": "",
              "schemaCode": null,
              "systemDate": false,
              "validations": [
                {
                  "type": "required",
                  "value": true,
                  "message":
                      "APPONE_MANAGESTOCK_WAREHOUSE_label_facilityToWhich_mandatory_message"
                },
                {
                  "type": "identityQr",
                  "value": true,
                  "message":
                      "APPONE_MANAGESTOCK_WAREHOUSE_label_teamCode_invalid_qr_message"
                }
              ],
              "errorMessage": "",
              "isMultiSelect": false,
              "dropDownOptions": [],
              "includeInSummary": true,
              "required.message":
                  "APPONE_MANAGESTOCK_WAREHOUSE_label_facilityToWhich_mandatory_message",
              "visibilityCondition": {
                "expression": [
                  {
                    "condition":
                        "warehouseDetails.facilityToWhich==DELIVERY_TEAM"
                  }
                ]
              }
            }
          ],
          "actionLabel": "APPONE_MANAGESTOCK_WAREHOUSE_ACTION_BUTTON_LABEL_1",
          "description": "APPONE_MANAGESTOCK_WAREHOUSE_SCREEN_DESCRIPTION",
          "showTabView": false,
          "submitCondition": null,
          "preventScreenCapture": false
        }
      ],
      "project": "CMP-2026-10-30-001379",
      "summary": false,
      "version": 3,
      "disabled": false,
      "onAction": [
        {
          "actionType": "FETCH_TRANSFORMER_CONFIG",
          "properties": {
            "data": [
              {
                "key": "stockEntryType",
                "value": "{{formData.lessExcessDetails.recordType}}"
              },
              {"key": "mrnNumber", "value": "{{navigation.mrnNumber}}"}
            ],
            "onError": [
              {
                "actionType": "SHOW_TOAST",
                "properties": {"message": "Failed to fetch config."}
              }
            ],
            "configName": "stockLessExcess"
          }
        },
        {
          "actionType": "CREATE_EVENT",
          "properties": {
            "entity": "STOCK",
            "onError": [
              {
                "actionType": "SHOW_TOAST",
                "properties": {"message": "Failed to create stock."}
              }
            ]
          }
        },
        {
          "actionType": "UPDATE_STOCK_BALANCE",
          "properties": {
            "entity": "STOCK",
            "onError": [
              {
                "actionType": "SHOW_TOAST",
                "properties": {"message": "Failed to update stock balance."}
              }
            ]
          }
        },
        {
          "actionType": "NAVIGATION",
          "properties": {
            "data": [
              {"key": "mrnNumber", "value": "{{navigation.mrnNumber}}"}
            ],
            "name": "stockSuccess",
            "type": "TEMPLATE",
            "onError": [
              {
                "actionType": "SHOW_TOAST",
                "properties": {"message": "Navigation failed."}
              }
            ],
            "navigationMode": "popUntilAndPush",
            "popUntilPageName": "manageStock"
          }
        }
      ],
      "isSelected": true,
      "screenType": "FORM",
      "initActions": [
        {
          "actionType": "SEARCH_EVENT",
          "properties": {
            "data": [
              {
                "key": "projectId",
                "value": "{{singleton.selectedProject.id}}",
                "operation": "equals"
              }
            ],
            "name": "projectFacility",
            "type": "SEARCH_EVENT",
            "awaitResults": true,
            "skipAccumulatedFilters": true
          }
        }
      ],
      "wrapperConfig": {
        "filters": [],
        "relations": [
          {
            "name": "facility",
            "match": {"field": "id", "equalsFrom": "facilityId"},
            "entity": "FacilityModel"
          },
          {
            "name": "productVariant",
            "match": {"field": "id", "equalsFrom": "resource"},
            "entity": "ProductVariantModel"
          }
        ],
        "rootEntity": "ProjectFacilityModel",
        "groupByType": true,
        "wrapperName": "InventoryWrapper",
        "searchConfig": {
          "select": ["projectFacility", "productVariant", "stock"],
          "primary": "projectFacility"
        }
      },
      "scrollListener": {}
    },
    {
      "name": "RECORDSTOCK",
      "order": 2,
      "pages": [
        {
          "body": null,
          "flow": "RECORDSTOCK",
          "page": "stockDetails",
          "type": "object",
          "label": "APPONE_INVENTORY_STOCKDETAILS_SCREEN_HEADING",
          "order": 2,
          "footer": [
            {
              "label": "APPONE_INVENTORY_STOCKDETAILS_ACTION_BUTTON_LABEL",
              "format": "button",
              "onAction": [
                {
                  "actionType": "NAVIGATION",
                  "properties": {"name": "stockProductDetails", "type": "form"}
                }
              ],
              "properties": {
                "size": "large",
                "type": "primary",
                "mainAxisSize": "max",
                "mainAxisAlignment": "center"
              }
            }
          ],
          "module": "INVENTORY",
          "heading": "APPONE_INVENTORY_STOCKDETAILS_SCREEN_HEADING",
          "project": "CMP-2026-10-30-001379",
          "summary": false,
          "version": 1,
          "onAction": [
            {
              "actionType": "FETCH_TRANSFORMER_CONFIG",
              "properties": {
                "data": [
                  {
                    "key": "stockEntryType",
                    "value": "{{navigation.stockEntryType}}"
                  },
                  {
                    "key": "transactionType",
                    "value": "{{navigation.transactionType}}"
                  },
                  {"key": "primaryRole", "value": "{{navigation.primaryRole}}"},
                  {
                    "key": "secondaryRole",
                    "value": "{{navigation.secondaryRole}}"
                  },
                  {
                    "key": "senderPartyType",
                    "value":
                        "{{fn:getSecondaryType(formData.stockDetails.facilityFromWhich)}}"
                  },
                  {
                    "key": "secondaryType",
                    "value":
                        "{{fn:getSecondaryType(formData.stockDetails.facilityFromWhich)}}"
                  },
                  {
                    "key": "receiverPartyType",
                    "value":
                        "{{fn:getSecondaryType(formData.warehouseDetails.facilityToWhich)}}"
                  },
                  {"key": "mrnNumber", "value": "{{navigation.mrnNumber}}"}
                ],
                "onError": [
                  {
                    "actionType": "SHOW_TOAST",
                    "properties": {"message": "Failed to fetch config."}
                  }
                ],
                "configName": "stock"
              }
            },
            {
              "actionType": "CREATE_EVENT",
              "properties": {
                "entity": "STOCK",
                "onError": [
                  {
                    "actionType": "SHOW_TOAST",
                    "properties": {"message": "Failed to create stock."}
                  }
                ]
              }
            },
            {
              "actionType": "UPDATE_STOCK_BALANCE",
              "properties": {
                "entity": "STOCK",
                "onError": [
                  {
                    "actionType": "SHOW_TOAST",
                    "properties": {"message": "Failed to update stock balance."}
                  }
                ]
              }
            },
            {
              "actionType": "NAVIGATION",
              "properties": {
                "data": [
                  {"key": "mrnNumber", "value": "{{navigation.mrnNumber}}"}
                ],
                "name": "stockSuccess",
                "type": "TEMPLATE",
                "onError": [
                  {
                    "actionType": "SHOW_TOAST",
                    "properties": {"message": "Navigation failed."}
                  }
                ],
                "navigationMode": "popUntilAndPush",
                "popUntilPageName": "manageStock"
              }
            }
          ],
          "navigateTo": {"name": "stockProductDetails", "type": "form"},
          "properties": [
            {
              "type": "dynamic",
              "enums": null,
              "label": "APPONE_INVENTORY_PRODUCTDETAILS_LABEL",
              "order": 1,
              "value": "",
              "format": "custom",
              "hidden": false,
              "isMdms": true,
              "tooltip": "",
              "helpText": "",
              "infoText": "",
              "readOnly": false,
              "required": true,
              "fieldName": "productdetail",
              "mandatory": false,
              "deleteFlag": false,
              "innerLabel": "",
              "schemaCode": "HCM.DELIVERY_COMMENT_OPTIONS_POPULATOR",
              "systemDate": false,
              "validations": [
                {
                  "type": "required",
                  "value": true,
                  "message": "INVENTORY_PRODUCTDETAILS_REQUIRED_ERROR_MESSAGE"
                }
              ],
              "errorMessage": "",
              "isMultiSelect": true,
              "dropDownOptions": [],
              "required.message":
                  "INVENTORY_PRODUCTDETAILS_REQUIRED_ERROR_MESSAGE"
            },
            {
              "type": "dynamic",
              "enums": null,
              "label": "APPONE_MANAGESTOCK_WAREHOUSE_label_facilityFromWhich",
              "order": 2,
              "value": "",
              "format": "custom",
              "hidden": false,
              "isMdms": true,
              "tooltip": "",
              "helpText": "",
              "infoText": "",
              "readOnly": false,
              "required": true,
              "fieldName": "facilityFromWhich",
              "mandatory": false,
              "deleteFlag": false,
              "innerLabel": "",
              "notEqualTo": "warehouseDetails.facilityToWhich",
              "schemaCode": "HCM.FACILITY_OPTIONS_POPULATOR",
              "systemDate": false,
              "validations": [
                {
                  "type": "required",
                  "value": true,
                  "message":
                      "APPONE_MANAGESTOCK_WAREHOUSE_label_facilityToWhich_mandatory_message"
                },
                {
                  "type": "notEqualTo",
                  "value": "warehouseDetails.facilityToWhich",
                  "message": "Facility from and to must be different"
                }
              ],
              "errorMessage": "",
              "includeInForm": true,
              "isMultiSelect": false,
              "required.message":
                  "APPONE_MANAGESTOCK_WAREHOUSE_label_facilityToWhich_mandatory_message",
              "notEqualTo.message": "Facility from and to must be different"
            },
            {
              "type": "string",
              "enums": [],
              "label": "APPONE_MANAGESTOCK_WAREHOUSE_label_deliveryTeamCode",
              "order": 4,
              "value": "",
              "format": "scanner",
              "hidden": false,
              "isMdms": false,
              "tooltip": "",
              "helpText": "",
              "infoText": "",
              "readOnly": false,
              "required": true,
              "fieldName": "deliveryTeam",
              "mandatory": false,
              "deleteFlag": false,
              "innerLabel": "",
              "schemaCode": null,
              "systemDate": false,
              "validations": [
                {
                  "type": "required",
                  "value": true,
                  "message":
                      "APPONE_MANAGESTOCK_WAREHOUSE_label_facilityFromWhich_mandatory_message"
                },
                {
                  "type": "identityQr",
                  "value": true,
                  "message":
                      "APPONE_MANAGESTOCK_WAREHOUSE_label_teamCode_invalid_qr_message"
                }
              ],
              "errorMessage": "",
              "isMultiSelect": false,
              "dropDownOptions": [],
              "required.message":
                  "APPONE_MANAGESTOCK_WAREHOUSE_label_facilityFromWhich_mandatory_message",
              "visibilityCondition": {
                "expression": [
                  {"condition": "stockDetails.facilityFromWhich==DELIVERY_TEAM"}
                ]
              }
            },
            {
              "type": "string",
              "enums": [
                {"code": "BUS", "name": "Bus"},
                {"code": "TRUCK", "name": "Truck"},
                {
                  "code": "1d15294d-6afe-4e1a-939a-b4ed8960891e",
                  "name":
                      "OPTION_1d15294d-6afe-4e1a-939a-b4ed8960891e_1793359798592"
                }
              ],
              "label": "APPONE_INVENTORY_TRANSPORT_LABEL",
              "order": 3,
              "value": "",
              "format": "dropdown",
              "hidden": false,
              "isMdms": false,
              "tooltip": "",
              "helpText": "",
              "infoText": "",
              "readOnly": false,
              "fieldName": "transportType",
              "mandatory": false,
              "deleteFlag": false,
              "innerLabel": "",
              "schemaCode": null,
              "systemDate": false,
              "validations": [],
              "errorMessage": "",
              "isMultiSelect": false,
              "dropDownOptions": [
                {"code": "BUS", "name": "Bus"},
                {"code": "TRUCK", "name": "Truck"},
                {
                  "code": "1d15294d-6afe-4e1a-939a-b4ed8960891e",
                  "name":
                      "OPTION_1d15294d-6afe-4e1a-939a-b4ed8960891e_1793359798592"
                }
              ]
            },
            {
              "type": "string",
              "enums": null,
              "label": "APPONE_INVENTORY_VEHICLE_NUMBER_LABEL",
              "order": 4,
              "value": "",
              "format": "text",
              "hidden": true,
              "isMdms": false,
              "tooltip": "",
              "helpText": "",
              "infoText": "",
              "readOnly": false,
              "fieldName": "vehicleNumber",
              "mandatory": false,
              "deleteFlag": false,
              "innerLabel": "",
              "schemaCode": null,
              "systemDate": false,
              "validations": [],
              "errorMessage": "",
              "isMultiSelect": false
            }
          ],
          "actionLabel": "APPONE_INVENTORY_STOCKDETAILS_ACTION_BUTTON_LABEL",
          "description": "APPONE_INVENTORY_STOCKDETAILS_SCREEN_DESCRIPTION",
          "showTabView": false,
          "submitCondition": null,
          "preventScreenCapture": false
        },
        {
          "body": null,
          "flow": "RECORDSTOCK",
          "page": "warehouseDetails",
          "type": "object",
          "label": "APPONE_MANAGESTOCK_WAREHOUSE_SCREEN_HEADING",
          "order": 1,
          "footer": [
            {
              "label": "APPONE_MANAGESTOCK_WAREHOUSE_ACTION_BUTTON_LABEL_1",
              "format": "button",
              "onAction": [
                {
                  "actionType": "NAVIGATION",
                  "properties": {"name": "stockDetails", "type": "form"}
                }
              ],
              "properties": {
                "size": "large",
                "type": "primary",
                "mainAxisSize": "max",
                "mainAxisAlignment": "center"
              }
            }
          ],
          "module": "INVENTORY",
          "heading": "APPONE_MANAGESTOCK_WAREHOUSE_SCREEN_HEADING",
          "project": "CMP-2026-10-30-001379",
          "summary": false,
          "version": 1,
          "onAction": [
            {
              "actionType": "FETCH_TRANSFORMER_CONFIG",
              "properties": {
                "data": [
                  {
                    "key": "stockEntryType",
                    "value": "{{navigation.stockEntryType}}"
                  },
                  {
                    "key": "transactionType",
                    "value": "{{navigation.transactionType}}"
                  },
                  {"key": "primaryRole", "value": "{{navigation.primaryRole}}"},
                  {
                    "key": "secondaryRole",
                    "value": "{{navigation.secondaryRole}}"
                  },
                  {
                    "key": "senderPartyType",
                    "value":
                        "{{fn:getSecondaryType(formData.stockDetails.facilityFromWhich)}}"
                  },
                  {
                    "key": "secondaryType",
                    "value":
                        "{{fn:getSecondaryType(formData.stockDetails.facilityFromWhich)}}"
                  },
                  {
                    "key": "receiverPartyType",
                    "value":
                        "{{fn:getSecondaryType(formData.warehouseDetails.facilityToWhich)}}"
                  },
                  {"key": "mrnNumber", "value": "{{navigation.mrnNumber}}"}
                ],
                "onError": [
                  {
                    "actionType": "SHOW_TOAST",
                    "properties": {"message": "Failed to fetch config."}
                  }
                ],
                "configName": "stock"
              }
            },
            {
              "actionType": "CREATE_EVENT",
              "properties": {
                "entity": "STOCK",
                "onError": [
                  {
                    "actionType": "SHOW_TOAST",
                    "properties": {"message": "Failed to create stock."}
                  }
                ]
              }
            },
            {
              "actionType": "UPDATE_STOCK_BALANCE",
              "properties": {
                "entity": "STOCK",
                "onError": [
                  {
                    "actionType": "SHOW_TOAST",
                    "properties": {"message": "Failed to update stock balance."}
                  }
                ]
              }
            },
            {
              "actionType": "NAVIGATION",
              "properties": {
                "data": [
                  {"key": "mrnNumber", "value": "{{navigation.mrnNumber}}"}
                ],
                "name": "stockSuccess",
                "type": "TEMPLATE",
                "onError": [
                  {
                    "actionType": "SHOW_TOAST",
                    "properties": {"message": "Navigation failed."}
                  }
                ],
                "navigationMode": "popUntilAndPush",
                "popUntilPageName": "manageStock"
              }
            }
          ],
          "navigateTo": {"name": "stockDetails", "type": "form"},
          "properties": [
            {
              "type": "integer",
              "label": "APPONE_MANAGESTOCK_WAREHOUSE_label_dateOfReceipt",
              "order": 1,
              "value": "",
              "format": "date",
              "hidden": false,
              "isMdms": false,
              "tooltip": "",
              "helpText": "",
              "infoText": "",
              "readOnly": true,
              "required": true,
              "fieldName": "dateOfEntry",
              "mandatory": false,
              "deleteFlag": false,
              "innerLabel": "",
              "schemaCode": null,
              "systemDate": true,
              "validations": [
                {
                  "type": "required",
                  "value": true,
                  "message":
                      "APPONE_MANAGESTOCK_WAREHOUSE_label_dateOfReceipt_mandatory_message"
                }
              ],
              "errorMessage": "",
              "includeInForm": true,
              "isMultiSelect": false,
              "required.message":
                  "APPONE_MANAGESTOCK_WAREHOUSE_label_dateOfReceipt_mandatory_message"
            },
            {
              "type": "string",
              "label": "APPONE_MANAGESTOCK_WAREHOUSE_label_administrativeArea",
              "order": 2,
              "value": "",
              "format": "locality",
              "hidden": false,
              "isMdms": false,
              "tooltip": "",
              "helpText": "",
              "infoText": "",
              "readOnly": false,
              "required": true,
              "fieldName": "administrativeArea",
              "mandatory": false,
              "deleteFlag": false,
              "innerLabel": "",
              "schemaCode": null,
              "systemDate": false,
              "validations": [
                {
                  "type": "required",
                  "value": true,
                  "message":
                      "APPONE_MANAGESTOCK_WAREHOUSE_label_administrativeArea_mandatory_message"
                }
              ],
              "errorMessage": "",
              "includeInForm": true,
              "isMultiSelect": false,
              "required.message":
                  "APPONE_MANAGESTOCK_WAREHOUSE_label_administrativeArea_mandatory_message"
            },
            {
              "type": "dynamic",
              "enums": [],
              "label": "APPONE_MANAGESTOCK_WAREHOUSE_label_facilityToWhich",
              "order": 3,
              "value": "",
              "format": "custom",
              "hidden": false,
              "isMdms": false,
              "tooltip": "",
              "helpText": "",
              "infoText": "",
              "readOnly": false,
              "required": true,
              "fieldName": "facilityToWhich",
              "mandatory": false,
              "deleteFlag": false,
              "innerLabel": "",
              "schemaCode": null,
              "systemDate": false,
              "validations": [
                {
                  "type": "required",
                  "value": true,
                  "message":
                      "APPONE_MANAGESTOCK_WAREHOUSE_label_facilityToWhich_mandatory_message"
                }
              ],
              "errorMessage": "",
              "includeInForm": true,
              "isMultiSelect": false,
              "dropDownOptions": [],
              "required.message":
                  "APPONE_MANAGESTOCK_WAREHOUSE_label_facilityToWhich_mandatory_message"
            },
            {
              "type": "string",
              "enums": [],
              "label": "APP_CONFIG_INVENTORY_warehouseDetails_teamCode_LABEL",
              "order": 4,
              "value": "",
              "format": "scanner",
              "hidden": false,
              "isMdms": false,
              "tooltip": "",
              "helpText": "",
              "infoText": "",
              "readOnly": false,
              "required": true,
              "fieldName": "teamCode",
              "mandatory": false,
              "deleteFlag": false,
              "innerLabel": "",
              "schemaCode": null,
              "systemDate": false,
              "validations": [
                {
                  "type": "required",
                  "value": true,
                  "message":
                      "APPONE_MANAGESTOCK_WAREHOUSE_label_facilityToWhich_mandatory_message"
                },
                {
                  "type": "identityQr",
                  "value": true,
                  "message":
                      "APPONE_MANAGESTOCK_WAREHOUSE_label_teamCode_invalid_qr_message"
                }
              ],
              "errorMessage": "",
              "includeInForm": true,
              "isMultiSelect": false,
              "dropDownOptions": [],
              "includeInSummary": true,
              "required.message":
                  "APPONE_MANAGESTOCK_WAREHOUSE_label_facilityToWhich_mandatory_message",
              "visibilityCondition": {
                "expression": [
                  {
                    "condition":
                        "warehouseDetails.facilityToWhich==DELIVERY_TEAM"
                  }
                ]
              }
            }
          ],
          "actionLabel": "APPONE_MANAGESTOCK_WAREHOUSE_ACTION_BUTTON_LABEL_1",
          "description": "APPONE_MANAGESTOCK_WAREHOUSE_SCREEN_DESCRIPTION",
          "showTabView": false,
          "submitCondition": null,
          "preventScreenCapture": false
        },
        {
          "body": null,
          "flow": "RECORDSTOCK",
          "page": "stockProductDetails",
          "type": "object",
          "label": "APPONE_INVENTORY_PRODUCTDETAILS_SCREEN_HEADING",
          "order": 3,
          "footer": [
            {
              "label": "APPONE_INVENTORY_PRODUCTDETAILS_ACTION_BUTTON_LABEL_1",
              "format": "button",
              "onAction": [
                {
                  "actionType": "NAVIGATION",
                  "properties": {
                    "name": "stock-acknowledgement",
                    "type": "template"
                  }
                }
              ],
              "properties": {
                "size": "large",
                "type": "primary",
                "mainAxisSize": "max",
                "mainAxisAlignment": "center"
              }
            }
          ],
          "module": "INVENTORY",
          "heading": "APPONE_INVENTORY_PRODUCTDETAILS_SCREEN_HEADING",
          "project": "CMP-2026-10-30-001379",
          "summary": false,
          "version": 1,
          "onAction": [
            {
              "actionType": "FETCH_TRANSFORMER_CONFIG",
              "properties": {
                "data": [
                  {
                    "key": "stockEntryType",
                    "value": "{{navigation.stockEntryType}}"
                  },
                  {
                    "key": "transactionType",
                    "value": "{{navigation.transactionType}}"
                  },
                  {"key": "primaryRole", "value": "{{navigation.primaryRole}}"},
                  {
                    "key": "secondaryRole",
                    "value": "{{navigation.secondaryRole}}"
                  },
                  {
                    "key": "senderPartyType",
                    "value":
                        "{{fn:getSecondaryType(formData.stockDetails.facilityFromWhich)}}"
                  },
                  {
                    "key": "secondaryType",
                    "value":
                        "{{fn:getSecondaryType(formData.stockDetails.facilityFromWhich)}}"
                  },
                  {
                    "key": "receiverPartyType",
                    "value":
                        "{{fn:getSecondaryType(formData.warehouseDetails.facilityToWhich)}}"
                  },
                  {"key": "mrnNumber", "value": "{{navigation.mrnNumber}}"}
                ],
                "onError": [
                  {
                    "actionType": "SHOW_TOAST",
                    "properties": {"message": "Failed to fetch config."}
                  }
                ],
                "configName": "stock"
              }
            },
            {
              "actionType": "CREATE_EVENT",
              "properties": {
                "entity": "STOCK",
                "onError": [
                  {
                    "actionType": "SHOW_TOAST",
                    "properties": {"message": "Failed to create stock."}
                  }
                ]
              }
            },
            {
              "actionType": "UPDATE_STOCK_BALANCE",
              "properties": {
                "entity": "STOCK",
                "onError": [
                  {
                    "actionType": "SHOW_TOAST",
                    "properties": {"message": "Failed to update stock balance."}
                  }
                ]
              }
            },
            {
              "actionType": "NAVIGATION",
              "properties": {
                "data": [
                  {"key": "mrnNumber", "value": "{{navigation.mrnNumber}}"}
                ],
                "name": "stockSuccess",
                "type": "TEMPLATE",
                "onError": [
                  {
                    "actionType": "SHOW_TOAST",
                    "properties": {"message": "Navigation failed."}
                  }
                ],
                "navigationMode": "popUntilAndPush",
                "popUntilPageName": "manageStock"
              }
            }
          ],
          "navigateTo": {"name": "stock-acknowledgement", "type": "template"},
          "properties": [
            {
              "type": "string",
              "enums": null,
              "label": "APPONE_INVENTORY_WAYBILL_LABEL",
              "order": 1,
              "value": "",
              "format": "text",
              "hidden": false,
              "isMdms": false,
              "tooltip": "",
              "helpText": "",
              "infoText": "",
              "readOnly": false,
              "required": false,
              "fieldName": "wayBillNumber",
              "mandatory": false,
              "deleteFlag": false,
              "innerLabel": "",
              "schemaCode": null,
              "systemDate": false,
              "validations": [],
              "errorMessage": "",
              "isMultiSelect": false,
              "required.message":
                  "INVENTORY_WAYBILL_NUMBER_REQUIRED_ERROR_MESSAGE"
            },
            {
              "type": "string",
              "enums": null,
              "label": "APPONE_INVENTORY_BATCH_NUMBER_LABEL",
              "order": 2,
              "value": "",
              "format": "text",
              "hidden": true,
              "isMdms": false,
              "tooltip": "",
              "helpText": "",
              "infoText": "",
              "readOnly": false,
              "required": false,
              "fieldName": "batchNumber",
              "mandatory": false,
              "deleteFlag": false,
              "innerLabel": "",
              "schemaCode": null,
              "systemDate": false,
              "validations": [],
              "errorMessage": "",
              "isMultiSelect": false,
              "required.message":
                  "INVENTORY_BATCH_NUMBER_REQUIRED_ERROR_MESSAGE"
            },
            {
              "type": "integer",
              "enums": null,
              "label": "APPONE_INVENTORY_QUANTITY_SENT_LABEL",
              "order": 4,
              "range": {
                "min": 1,
                "errorMessage": "QUANTITY_SENT_MIN_REQUIRED_ERROR_MESSAGE"
              },
              "regex": r"^[0-9]+$",
              "value": "",
              "format": "text",
              "hidden": false,
              "isMdms": false,
              "tooltip": "",
              "helpText": "",
              "infoText": "",
              "readOnly": false,
              "required": true,
              "fieldName": "quantitySent",
              "mandatory": false,
              "deleteFlag": false,
              "innerLabel": "",
              "schemaCode": null,
              "systemDate": false,
              "validations": [
                {
                  "type": "required",
                  "value": true,
                  "message": "QUANTITY_SENT_REQUIRED_ERROR_MESSAGE"
                },
                {
                  "type": "min",
                  "value": 1,
                  "message": "QUANTITY_SENT_MIN_REQUIRED_ERROR_MESSAGE"
                },
                {
                  "type": "regex",
                  "value": r"^[0-9]+$",
                  "message": "QUANTITY_VALID_NUMBER_ERROR_MESSAGE"
                }
              ],
              "errorMessage": "",
              "isMultiSelect": false,
              "regex.message": "QUANTITY_VALID_NUMBER_ERROR_MESSAGE",
              "required.message": "QUANTITY_SENT_REQUIRED_ERROR_MESSAGE",
              "visibilityCondition": {
                "expression": [
                  {
                    "type": "custom",
                    "condition": "navigation.stockEntryType == 'ISSUED'"
                  }
                ]
              }
            },
            {
              "type": "integer",
              "enums": null,
              "label": "APPONE_INVENTORY_QUANTITY_LOST_LABEL",
              "order": 4,
              "range": {
                "min": 1,
                "errorMessage": "QUANTITY_LOST_MIN_REQUIRED_ERROR_MESSAGE"
              },
              "regex": r"^[0-9]+$",
              "value": "",
              "format": "text",
              "hidden": false,
              "isMdms": false,
              "tooltip": "",
              "helpText": "",
              "infoText": "",
              "readOnly": false,
              "required": true,
              "fieldName": "quantityLost",
              "mandatory": false,
              "deleteFlag": false,
              "innerLabel": "",
              "schemaCode": null,
              "systemDate": false,
              "validations": [
                {
                  "type": "required",
                  "value": true,
                  "message": "QUANTITY_LOST_REQUIRED_ERROR_MESSAGE"
                },
                {
                  "type": "min",
                  "value": 1,
                  "message": "QUANTITY_LOST_MIN_REQUIRED_ERROR_MESSAGE"
                },
                {
                  "type": "regex",
                  "value": r"^[0-9]+$",
                  "message": "QUANTITY_VALID_NUMBER_ERROR_MESSAGE"
                }
              ],
              "errorMessage": "",
              "isMultiSelect": false,
              "regex.message": "QUANTITY_VALID_NUMBER_ERROR_MESSAGE",
              "required.message": "QUANTITY_LOST_REQUIRED_ERROR_MESSAGE",
              "visibilityCondition": {
                "expression": [
                  {
                    "type": "custom",
                    "condition": "navigation.stockEntryType == 'LOSS'"
                  }
                ]
              }
            },
            {
              "type": "integer",
              "enums": null,
              "label": "APPONE_INVENTORY_QUANTITY_DAMAGED_LABEL",
              "order": 4,
              "range": {
                "min": 1,
                "errorMessage": "QUANTITY_DAMAGE_MIN_REQUIRED_ERROR_MESSAGE"
              },
              "regex": r"^[0-9]+$",
              "value": "",
              "format": "text",
              "hidden": false,
              "isMdms": false,
              "tooltip": "",
              "helpText": "",
              "infoText": "",
              "readOnly": false,
              "required": true,
              "fieldName": "quantityDamaged",
              "mandatory": false,
              "deleteFlag": false,
              "innerLabel": "",
              "schemaCode": null,
              "systemDate": false,
              "validations": [
                {
                  "type": "required",
                  "value": true,
                  "message": "QUANTITY_DAMAGE_REQUIRED_ERROR_MESSAGE"
                },
                {
                  "type": "min",
                  "value": 1,
                  "message": "QUANTITY_DAMAGE_MIN_REQUIRED_ERROR_MESSAGE"
                },
                {
                  "type": "regex",
                  "value": r"^[0-9]+$",
                  "message": "QUANTITY_VALID_NUMBER_ERROR_MESSAGE"
                }
              ],
              "errorMessage": "",
              "isMultiSelect": false,
              "regex.message": "QUANTITY_VALID_NUMBER_ERROR_MESSAGE",
              "required.message": "QUANTITY_DAMAGE_REQUIRED_ERROR_MESSAGE",
              "visibilityCondition": {
                "expression": [
                  {
                    "type": "custom",
                    "condition": "navigation.stockEntryType == 'DAMAGED'"
                  }
                ]
              }
            },
            {
              "type": "integer",
              "enums": null,
              "label": "APPONE_INVENTORY_QUANTITY_RETURNED_LABEL",
              "order": 4,
              "range": {
                "min": 1,
                "errorMessage": "QUANTITY_RETURN_MIN_REQUIRED_ERROR_MESSAGE"
              },
              "regex": r"^[0-9]+$",
              "value": "",
              "format": "text",
              "hidden": false,
              "isMdms": false,
              "tooltip": "",
              "helpText": "",
              "infoText": "",
              "readOnly": false,
              "required": true,
              "fieldName": "quantityReturned",
              "mandatory": false,
              "deleteFlag": false,
              "innerLabel": "",
              "schemaCode": null,
              "systemDate": false,
              "validations": [
                {
                  "type": "required",
                  "value": true,
                  "message": "QUANTITY_RETURN_REQUIRED_ERROR_MESSAGE"
                },
                {
                  "type": "min",
                  "value": 1,
                  "message": "QUANTITY_RETURN_MIN_REQUIRED_ERROR_MESSAGE"
                },
                {
                  "type": "regex",
                  "value": r"^[0-9]+$",
                  "message": "QUANTITY_VALID_NUMBER_ERROR_MESSAGE"
                }
              ],
              "errorMessage": "",
              "isMultiSelect": false,
              "regex.message": "QUANTITY_VALID_NUMBER_ERROR_MESSAGE",
              "required.message": "QUANTITY_RETURN_REQUIRED_ERROR_MESSAGE",
              "visibilityCondition": {
                "expression": [
                  {
                    "type": "custom",
                    "condition": "navigation.stockEntryType == 'RETURNED'"
                  }
                ]
              }
            },
            {
              "type": "integer",
              "enums": null,
              "label": "APPONE_INVENTORY_QUANTITY_RECEIVED_LABEL",
              "order": 4,
              "regex": r"^[0-9]+$",
              "value": "",
              "format": "text",
              "hidden": false,
              "isMdms": false,
              "tooltip": "",
              "helpText": "",
              "infoText": "",
              "readOnly": false,
              "required": true,
              "fieldName": "quantityReceived",
              "mandatory": false,
              "deleteFlag": false,
              "innerLabel": "",
              "schemaCode": null,
              "systemDate": false,
              "validations": [
                {
                  "type": "required",
                  "value": true,
                  "message": "QUANTITY_RECEIVED_REQUIRED_ERROR_MESSAGE"
                },
                {
                  "type": "regex",
                  "value": r"^[0-9]+$",
                  "message": "QUANTITY_VALID_NUMBER_ERROR_MESSAGE"
                }
              ],
              "errorMessage": "",
              "isMultiSelect": false,
              "regex.message": "QUANTITY_VALID_NUMBER_ERROR_MESSAGE",
              "required.message": "QUANTITY_RECEIVED_REQUIRED_ERROR_MESSAGE",
              "visibilityCondition": {
                "expression": [
                  {
                    "type": "custom",
                    "condition": "navigation.stockEntryType == 'RECEIPT'"
                  }
                ]
              }
            },
            {
              "type": "string",
              "enums": null,
              "label": "APPONE_INVENTORY_COMMENT_LABEL",
              "order": 9,
              "value": "",
              "format": "textArea",
              "hidden": false,
              "isMdms": false,
              "tooltip": "",
              "helpText": "",
              "infoText": "",
              "readOnly": false,
              "required": false,
              "fieldName": "comment",
              "mandatory": false,
              "deleteFlag": false,
              "innerLabel": "",
              "schemaCode": null,
              "systemDate": false,
              "validations": [],
              "errorMessage": "",
              "isMultiSelect": false,
              "required.message":
                  "QUANTITY_DIFFER_COMMENT_REQUIRED_ERROR_MASSAGE",
              "visibilityCondition": {
                "expression": [
                  {
                    "condition":
                        "stockProductDetails.quantitySent!=stockProductDetails.quantityReceived"
                  }
                ]
              }
            },
            {
              "type": "string",
              "enums": [],
              "isGS1": true,
              "label": "APPONE_MANAGESTOCK_WAREHOUSE_label_scanResource",
              "order": 10,
              "value": "",
              "format": "scanner",
              "hidden": false,
              "isMdms": false,
              "tooltip": "",
              "helpText": "",
              "infoText": "",
              "readOnly": false,
              "fieldName": "scanResource",
              "mandatory": false,
              "deleteFlag": false,
              "innerLabel": "",
              "schemaCode": null,
              "systemDate": false,
              "validations": [
                {"type": "isGS1", "value": true}
              ],
              "errorMessage": "",
              "isMultiSelect": false,
              "dropDownOptions": [],
              "comparisonConfig": {
                "model": "stock",
                "filters": [
                  {
                    "key": "senderId",
                    "value": "{{navigation.facilityFromWhich}}",
                    "operation": "equals"
                  },
                  {
                    "key": "receiverId",
                    "value": "{{navigation.facilityToWhich}}",
                    "operation": "equals"
                  },
                  {
                    "key": "productVariantId",
                    "value": "{{navigation.currentEntityId}}",
                    "operation": "equals"
                  },
                  {
                    "key": "additionalFields.stockEntryType",
                    "value": "{{navigation.stockEntryType}}",
                    "operation": "equals"
                  }
                ],
                "extractKey": "scanResource",
                "extractFrom": "additionalFields",
                "errorMessage": "RESOURCES_ALREADY_SCANNED"
              }
            }
          ],
          "actionLabel":
              "APPONE_INVENTORY_PRODUCTDETAILS_ACTION_BUTTON_LABEL_1",
          "description": "APPONE_INVENTORY_PRODUCTDETAILS_SCREEN_DESCRIPTION",
          "showTabView": true,
          "submitCondition": null,
          "multiEntityConfig": {
            "sourcePageKey": "stockDetails",
            "sourceFieldKey": "productdetail"
          },
          "preventScreenCapture": false,
          "conditionalNavigateTo": null
        }
      ],
      "project": "CMP-2026-10-30-001379",
      "summary": false,
      "version": 3,
      "disabled": false,
      "onAction": [
        {
          "actionType": "FETCH_TRANSFORMER_CONFIG",
          "properties": {
            "data": [
              {
                "key": "stockEntryType",
                "value": "{{navigation.stockEntryType}}"
              },
              {
                "key": "transactionType",
                "value": "{{navigation.transactionType}}"
              },
              {"key": "primaryRole", "value": "{{navigation.primaryRole}}"},
              {"key": "secondaryRole", "value": "{{navigation.secondaryRole}}"},
              {
                "key": "senderPartyType",
                "value":
                    "{{fn:getSecondaryType(formData.stockDetails.facilityFromWhich)}}"
              },
              {
                "key": "secondaryType",
                "value":
                    "{{fn:getSecondaryType(formData.stockDetails.facilityFromWhich)}}"
              },
              {
                "key": "receiverPartyType",
                "value":
                    "{{fn:getSecondaryType(formData.warehouseDetails.facilityToWhich)}}"
              },
              {"key": "mrnNumber", "value": "{{navigation.mrnNumber}}"}
            ],
            "onError": [
              {
                "actionType": "SHOW_TOAST",
                "properties": {"message": "Failed to fetch config."}
              }
            ],
            "configName": "stock"
          }
        },
        {
          "actionType": "CREATE_EVENT",
          "properties": {
            "entity": "STOCK",
            "onError": [
              {
                "actionType": "SHOW_TOAST",
                "properties": {"message": "Failed to create stock."}
              }
            ]
          }
        },
        {
          "actionType": "UPDATE_STOCK_BALANCE",
          "properties": {
            "entity": "STOCK",
            "onError": [
              {
                "actionType": "SHOW_TOAST",
                "properties": {"message": "Failed to update stock balance."}
              }
            ]
          }
        },
        {
          "actionType": "NAVIGATION",
          "properties": {
            "data": [
              {"key": "mrnNumber", "value": "{{navigation.mrnNumber}}"}
            ],
            "name": "stockSuccess",
            "type": "TEMPLATE",
            "onError": [
              {
                "actionType": "SHOW_TOAST",
                "properties": {"message": "Navigation failed."}
              }
            ],
            "navigationMode": "popUntilAndPush",
            "popUntilPageName": "manageStock"
          }
        }
      ],
      "isSelected": true,
      "screenType": "FORM",
      "initActions": [
        {
          "actionType": "SEARCH_EVENT",
          "properties": {
            "data": [
              {
                "key": "projectId",
                "value": "{{singleton.selectedProject.id}}",
                "operation": "equals"
              }
            ],
            "name": "projectFacility",
            "type": "SEARCH_EVENT",
            "awaitResults": true,
            "skipAccumulatedFilters": true
          }
        }
      ],
      "wrapperConfig": {
        "filters": [],
        "relations": [
          {
            "name": "facility",
            "match": {"field": "id", "equalsFrom": "facilityId"},
            "entity": "FacilityModel"
          },
          {
            "name": "productVariant",
            "match": {"field": "id", "equalsFrom": "resource"},
            "entity": "ProductVariantModel"
          }
        ],
        "rootEntity": "ProjectFacilityModel",
        "groupByType": true,
        "wrapperName": "InventoryWrapper",
        "searchConfig": {
          "select": ["projectFacility", "productVariant", "stock"],
          "primary": "projectFacility"
        }
      },
      "scrollListener": {}
    }
  ],
};
